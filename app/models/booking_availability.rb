class BookingAvailability
  CAPACITY_STATUSES = %w[agendado em_operacao liberado].freeze
  attr_reader :date, :dock_number

  def initialize(date:, dock_number:, now: Time.current, occupied_slots: nil, excluding_booking_id: nil)
    @date = date
    @dock_number = Integer(dock_number.to_s, 10, exception: false)
    @now = now
    @occupied = []
    @blocked = []
    @valid = AgendaDefinition.permitted_date?(date, now: @now) && AgendaDefinition::DOCK_NUMBERS.cover?(@dock_number)
    return unless @valid

    unless occupied_slots.nil?
      @occupied = occupied_slots
      return
    end

    reservations = Booking.where(booking_date: date, dock_number: @dock_number, status: CAPACITY_STATUSES)
    reservations = reservations.where.not(id: excluding_booking_id) if excluding_booking_id
    @occupied = reservations.pluck(:slot_number)
    @blocked = SlotBlock.where(blocked_date: date, dock_number: @dock_number).pluck(:slot_number)
    @occupied |= @blocked
  end

  def blocked?(number)
    @blocked.include?(number)
  end

  def available?(number)
    @valid && AgendaDefinition.future_slot?(date, number, now: @now) && !@occupied.include?(number)
  end
end
