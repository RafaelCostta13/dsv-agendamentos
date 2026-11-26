class ChangeBooking
  AUDIT_FIELDS = %w[booking_date dock_number slot_number status change_reason lock_version].freeze
  attr_reader :booking, :form, :http_status, :notice, :version_conflict

  def initialize(booking_id:, action:, form:, actor: nil)
    raise ArgumentError, "Unknown schedule change" unless %w[cancel reschedule].include?(action)

    @booking_id = booking_id
    @action = action
    @form = form
    @http_status = :unprocessable_entity
    @version_conflict = false
    @actor = actor
  end

  def call
    ApplicationRecord.transaction(requires_new: true) do
      return reject(:base, "Sua autorização foi alterada. Entre novamente.", :forbidden) if @actor && !User.lock.find_by(id: @actor.id, active: true)&.role.in?(%w[admin operator])
      @booking = Booking.find(@booking_id)
      original = @booking.agenda_position
      original_version = @booking.lock_version
      original_request = @booking.request_id
      AgendaCapacityLock.lock_request!(original_request)
      positions = [ original, (@action == "reschedule" ? form.position : nil) ].compact
      positions.map { |position| position.fetch(:dock_number) }.uniq.sort.each { |dock| AgendaCapacityLock.lock_dock!(dock_number: dock) }
      AgendaCapacityLock.lock_positions!(positions)
      @booking.reload(lock: true)
      unless current_version? && @booking.lock_version == original_version && @booking.agenda_position == original && @booking.request_id == original_request
        return stale_version
      end
      return reject(:base, BookingCheckinPolicy::MESSAGES.fetch(:status), :conflict) unless @booking.schedule_change_allowed?

      if @action == "reschedule" && @booking.status == "agendado" && form.position == original
        @notice = "Nenhuma alteração foi realizada."
        return true
      end
      return false unless form.valid?(@action.to_sym)
      return false if @action == "reschedule" && !destination_available?

      previous = @booking.attributes.slice(*AUDIT_FIELDS)
      old_status = @booking.status
      changes = @action == "cancel" ? { status: "cancelado", change_reason: form.change_reason } : form.booking_changes.merge(status: "agendado")
      @booking.update!(changes)
      AuditEvent.record!({ entity_type: "Booking", entity_id: @booking.id, action: @action, reason: form.change_reason,
        previous_values: previous, new_values: @booking.attributes.slice(*AUDIT_FIELDS) }, actor: @actor)
      @notice = if @action == "cancel"
        "Agendamento cancelado com sucesso."
      elsif old_status == "reagendamento"
        "Agendamento reagendado com sucesso."
      else
        "Agendamento alterado com sucesso."
      end
      true
    end
  rescue ActiveRecord::RecordNotFound
    raise
  rescue ActiveRecord::RecordNotUnique
    reject(:slot_number, "O horário selecionado não está mais disponível. Selecione outro horário.", :conflict)
  rescue ActiveRecord::StaleObjectError, ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked
    stale_version
  rescue ActiveRecord::ActiveRecordError
    reject(:base, "Não foi possível concluir a operação. Nenhuma alteração foi confirmada. Tente novamente.", :service_unavailable)
  end

  private

  def current_version?
    form.lock_version.match?(/\A[0-9]{1,10}\z/) && form.lock_version.to_i == @booking.lock_version
  end

  def stale_version
    @version_conflict = true
    reject(:base, OperateBooking::VERSION_MESSAGE, :conflict)
  end

  def destination_available?
    availability = BookingAvailability.new(date: form.booking_date, dock_number: form.dock_number, excluding_booking_id: @booking.id)
    slot = form.position.fetch(:slot_number)
    return true if availability.available?(slot)

    message = availability.blocked?(slot) ? "A posição selecionada está bloqueada." : "O horário selecionado não está mais disponível. Selecione outro horário."
    reject(:slot_number, message, :conflict)
  end

  def reject(field, message, status = :unprocessable_entity)
    @http_status = status
    form.errors.add(field, message)
    false
  end
end
