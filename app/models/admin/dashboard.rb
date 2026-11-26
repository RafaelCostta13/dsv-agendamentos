module Admin
  class Dashboard
    Cell = Data.define(:state, :booking, :block)
    attr_reader :date, :indicators, :pending_reschedules

    def initialize(date:, now: Time.current)
      @date = date
      @now = now
      @pending_reschedules = Booking.where(status: "reagendamento").count
      bookings = Booking.where(booking_date: date, status: BookingAvailability::CAPACITY_STATUSES).to_a
      blocks = SlotBlock.where(blocked_date: date).to_a
      @bookings = bookings.index_by { |booking| [ booking.dock_number, booking.slot_number ] }
      @blocks = blocks.index_by { |block| [ block.dock_number, block.slot_number ] }
      @availability = AgendaDefinition::DOCK_NUMBERS.index_with do |dock|
        occupied = bookings.select { |booking| booking.dock_number == dock }.map(&:slot_number)
        occupied |= blocks.select { |block| block.dock_number == dock }.map(&:slot_number)
        BookingAvailability.new(date: date, dock_number: dock, now: now, occupied_slots: occupied)
      end
      @indicators = {
        bookings: bookings.size,
        available: @availability.values.sum { |availability| AgendaDefinition::SLOT_NUMBERS.count { |slot| availability.available?(slot) } },
        deliveries: bookings.count { |booking| booking.operation == "entrega" },
        pickups: bookings.count { |booking| booking.operation == "coleta" }
      }
    end

    def cell(dock, slot)
      booking = @bookings[[ dock, slot ]]
      blocked = @blocks.key?([ dock, slot ])
      state = if booking && blocked
        "inconsistent"
      elsif booking
        booking.status
      elsif blocked
        "blocked"
      elsif @availability.fetch(dock).available?(slot)
        "available"
      elsif date > @now.to_date && !AgendaDefinition.permitted_date?(date, now: @now)
        "outside_horizon"
      else
        "ended"
      end
      Cell.new(state: state, booking: booking, block: @blocks[[ dock, slot ]])
    end
  end
end
