module Admin
  class BookingChangesController < BaseController
    before_action :load_booking

    def edit
      @change = BookingChangeRequest.new(booking_date: initial_date, dock_number: @booking.dock_number,
        slot_number: @booking.slot_number, lock_version: @booking.lock_version)
      prepare_availability
      render :edit, status: (@booking.schedule_change_allowed? ? :ok : :conflict)
    end

    def cancellation
      @change = BookingChangeRequest.new(lock_version: @booking.lock_version)
      render :cancellation, status: (@booking.schedule_change_allowed? ? :ok : :conflict)
    end

    def cancel
      @change = BookingChangeRequest.new(params.require(:booking).permit(:change_reason, :lock_version).to_h)
      perform_change("cancel")
    end

    def reschedule
      input = params.require(:booking).permit(*BookingChangeRequest::FIELDS).to_h
      selections = params.permit(:selected_date, :selected_dock)
      input["booking_date"] = selections[:selected_date] if params.key?(:selected_date)
      input["dock_number"] = selections[:selected_dock] if params.key?(:selected_dock)
      @change = BookingChangeRequest.new(input)
      if params.key?(:selected_date) || params.key?(:selected_dock) || params[:intent] == "availability"
        prepare_availability
        render :edit, status: preview_status
      elsif params[:intent] == "review"
        review
      else
        perform_change("reschedule")
      end
    end

    private

    def load_booking
      @booking = Booking.find(params[:id])
      filters.valid?
    end

    def initial_date
      AgendaDefinition.permitted_date?(@booking.booking_date) ? @booking.booking_date : Date.current
    end

    def prepare_availability
      @dates = (Date.current..Date.current + 2).to_a
      @availability = BookingAvailability.new(date: @change.booking_date, dock_number: @change.dock_number, excluding_booking_id: @booking.id)
      @change.slot_number = nil unless @availability.available?(@change.slot_number.to_i)
    end

    def preview_status
      unless @booking.schedule_change_allowed?
        @change.errors.add(:base, BookingCheckinPolicy::MESSAGES.fetch(:status))
        return :conflict
      end
      unless @change.lock_version.match?(/\A[0-9]{1,10}\z/) && @change.lock_version.to_i == @booking.lock_version
        @version_conflict = true
        @change.errors.add(:base, OperateBooking::VERSION_MESSAGE)
        return :conflict
      end
      :ok
    end

    def review
      status = preview_status
      if status == :ok
        unchanged = @booking.status == "agendado" && @change.position == @booking.agenda_position
        if unchanged || @change.valid?(:reschedule)
          availability = BookingAvailability.new(date: @change.booking_date, dock_number: @change.dock_number, excluding_booking_id: @booking.id)
          if unchanged || availability.available?(@change.slot_number.to_i)
            @unchanged = unchanged
            return render :review
          end
          @change.errors.add(:slot_number, availability.blocked?(@change.slot_number.to_i) ? "A posição selecionada está bloqueada." : "O horário selecionado não está mais disponível. Selecione outro horário.")
          status = :conflict
        else
          status = :unprocessable_entity
        end
      end
      prepare_availability
      render :edit, status: status
    end

    def perform_change(action)
      operation = ChangeBooking.new(booking_id: @booking.id, action: action, form: @change, actor: current_user)
      if operation.call
        redirect_to admin_booking_path(operation.booking, admin_context), status: :see_other, notice: operation.notice
      else
        @booking.reload
        @version_conflict = operation.version_conflict
        prepare_availability if action == "reschedule"
        render(action == "cancel" ? :cancellation : :edit, status: operation.http_status)
      end
    end
  end
end
