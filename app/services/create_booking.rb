class CreateBooking
  def self.call(form)
    new(form).call
  end

  def initialize(form)
    @form = form
  end

  def call
    return unless @form.valid?

    attempts = 0
    begin
      attempts += 1
      ApplicationRecord.transaction(requires_new: true) do
        AgendaCapacityLock.lock_request!(@form.request_id)
        existing = Booking.lock.find_by(request_id: @form.request_id)
        existing ? replay(existing) : create_new
      end
    rescue ActiveRecord::RecordNotUnique => error
      constraint = error.cause&.result&.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
      retry if constraint == "index_bookings_on_protocol" && attempts < 3

      if constraint == "index_bookings_on_request_id" && (existing = Booking.lock.find_by(request_id: @form.request_id))
        replay(existing)
      else
        @form.errors.add(:slot_number, :conflict, message: "Este horário acabou de ser reservado. Selecione outro horário disponível.")
        nil
      end
    rescue ActiveRecord::ActiveRecordError
      @form.errors.add(:base, "Não foi possível confirmar o agendamento. Tente novamente.")
      nil
    end
  end

  private

  def replay(booking)
    original = original_attributes(booking)
    if @form.booking_attributes.all? { |field, value| original.fetch(field) == value }
      booking
    else
      @form.errors.add(:base, :conflict, message: "Esta tentativa já foi utilizada com outros dados. Inicie um novo agendamento.")
      nil
    end
  end

  def original_attributes(booking)
    attributes = BookingRequest::FIELDS.index_with { |field| booking.public_send(field) }
    event = AuditEvent.where(entity_type: "Booking", entity_id: booking.id, action: %w[create reschedule cancel no_show]).order(:id).first
    position = event&.action == "create" ? event.new_values : event&.previous_values
    if position && %w[booking_date dock_number slot_number].all? { |key| position.key?(key) }
      attributes.merge!(booking_date: Date.iso8601(position.fetch("booking_date")),
        dock_number: position.fetch("dock_number").to_i, slot_number: position.fetch("slot_number").to_i)
    end
    attributes
  end

  def create_new
    AgendaCapacityLock.lock!(date: @form.booking_date, dock_number: @form.dock_number, slot_number: @form.slot_number)
    return unless @form.valid?(:new_booking)

    availability = BookingAvailability.new(date: @form.booking_date, dock_number: @form.dock_number)
    unless availability.available?(@form.slot_number.to_i)
      @form.errors.add(:slot_number, :conflict, message: "Este horário não está mais disponível. Selecione outro horário.")
      return
    end
    booking = Booking.create!(@form.booking_attributes.merge(protocol: "DA-#{SecureRandom.hex(12).upcase}", status: "agendado"))
    AuditEvent.record!({ entity_type: "Booking", entity_id: booking.id, action: "create",
      new_values: booking.attributes.slice("protocol", "booking_date", "dock_number", "slot_number", "operation", "status") }, origin: "public_form")
    booking
  end
end
