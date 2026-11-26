module Admin
  class BookingsController < BaseController
    include BookingReceiptRendering
    PAGE_SIZE = 25

    def receipt
      @booking = Booking.find(params[:id])
      filters.valid?
      render_booking_receipt("admin/bookings/receipt")
    end

    def index
      load_bookings
    end

    def export
      unless filters.valid?
        load_bookings
        return render :index, formats: [ :html ], status: :unprocessable_entity
      end
      export = ExportBookingsXlsx.new(filters)
      data = export.call
      AuditEvent.record!({ entity_type: "User", entity_id: current_user.id, action: "booking_exported",
        new_values: { "record_count" => export.row_count, "filters" => filters.query_parameters } }, actor: current_user)
      send_data data, type: ExportBookingsXlsx::MIME_TYPE, disposition: "attachment", filename: export.filename
    rescue ExportBookingsXlsx::Rejected => error
      @export_error = error.message
      load_bookings
      render :index, formats: [ :html ], status: :unprocessable_entity
    rescue StandardError => error
      Rails.logger.error("booking_export response_failed error_class=#{error.class.name}")
      render "admin/shared/error", formats: [ :html ], locals: { title: "Exportação indisponível", message: "Não foi possível gerar o arquivo Excel. Tente novamente." }, status: :service_unavailable
    end

    def load_bookings
      scope = filters.scope
      @total_count = scope.count
      @total_pages = [ (@total_count.to_f / PAGE_SIZE).ceil, 1 ].max
      requested_page = params[:page].to_s.match?(/\A[0-9]{1,9}\z/) ? params[:page].to_i : 1
      @page = requested_page.clamp(1, @total_pages)
      @bookings = scope.order(:booking_date, :slot_number, :dock_number, :id).limit(PAGE_SIZE).offset((@page - 1) * PAGE_SIZE).to_a
    end

    private :load_bookings

    def show
      @booking = Booking.find(params[:id])
      filters.valid?
      @checkin_reason = BookingCheckinPolicy.reason(@booking) if @booking.status == "agendado"
      @history = AuditPage.new(scope: AuditEvent.where(entity_type: "Booking", entity_id: @booking.id), page: params[:history_page], chronological: true)
    end

    def confirm_checkin
      prepare_operation("checkin")
    end

    def confirm_release
      prepare_operation("release")
    end

    def checkin
      perform_operation("checkin")
    end

    def release
      perform_operation("release")
    end

    private

    def prepare_operation(action)
      @booking = Booking.find(params[:id])
      filters.valid?
      @operation = OperateBooking.new(booking_id: @booking.id, action: action, lock_version: @booking.lock_version, actor: current_user)
      @operation_action = action
      @checkin_reason = BookingCheckinPolicy.reason(@booking) if action == "checkin"
      render :operation
    end

    def perform_operation(action)
      permitted = params.require(:booking).permit(*(action == "release" ? %i[release_remark lock_version] : %i[lock_version]))
      @operation = OperateBooking.new(booking_id: params[:id], action: action,
        lock_version: permitted[:lock_version], release_remark: permitted[:release_remark], actor: current_user)
      filters.valid?
      if @operation.call
        redirect_to admin_booking_path(@operation.booking, admin_context), status: :see_other,
          notice: action == "checkin" ? "Check-in registrado com sucesso." : "Doca liberada com sucesso."
      else
        @booking = Booking.find(params[:id])
        filters.valid?
        @operation_action = action
        @checkin_reason = BookingCheckinPolicy.reason(@booking) if action == "checkin"
        render :operation, status: @operation.http_status
      end
    end
  end
end
