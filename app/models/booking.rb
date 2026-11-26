class Booking < ApplicationRecord
  OPERATIONS = %w[entrega coleta].freeze
  STATUSES = %w[agendado em_operacao liberado cancelado reagendamento].freeze

  validates :protocol, :request_id, :booking_date, :contact_name, :company, :invoice,
    :plate, :vehicle_model, presence: true
  validates :protocol, length: { maximum: 50 }
  validates :contact_name, :vehicle_model, length: { maximum: 80 }
  validates :company, length: { maximum: 100 }
  validates :plate, length: { maximum: 7 }
  validates :invoice, format: { with: /\A[0-9]{1,44}\z/ }
  validates :dock_number, numericality: { only_integer: true, in: AgendaDefinition::DOCK_NUMBERS }
  validates :slot_number, numericality: { only_integer: true, in: AgendaDefinition::SLOT_NUMBERS }
  validates :operation, inclusion: { in: OPERATIONS }
  validates :status, inclusion: { in: STATUSES }
  validates :lock_version, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :checkin_at, presence: true, if: -> { status.in?(%w[em_operacao liberado]) }
  validates :released_at, presence: true, if: -> { status == "liberado" }

  validate :release_chronology
  validate :released_remark_length

  def schedule_change_allowed?
    status.in?(%w[agendado reagendamento])
  end

  def agenda_position
    { date: booking_date, dock_number: dock_number, slot_number: slot_number }
  end

  def operation_overdue?(now: Time.current)
    status == "em_operacao" && now >= AgendaDefinition.slot_end(booking_date, slot_number)
  end

  def arrival_state(now: Time.current)
    return unless status == "agendado" && checkin_at.nil?
    return :no_show if no_show_due?(now: now)
    return :awaiting_arrival if now < AgendaDefinition.slot_start(booking_date, slot_number)
    return :late_arrival if now >= AgendaDefinition.slot_end(booking_date, slot_number)

    :awaiting_checkin
  end

  def late_arrival?(now: Time.current)
    arrival_state(now: now) == :late_arrival
  end

  def no_show_due?(now: Time.current)
    status == "agendado" && checkin_at.nil? && booking_date <= AgendaDefinition.no_show_date_limit(now: now)
  end

  private

  def release_chronology
    return if released_at.nil?

    if checkin_at.nil? || released_at < checkin_at
      errors.add(:released_at, :invalid)
    end
  end

  def released_remark_length
    return unless status == "liberado"

    unless release_remark.to_s.strip.length.between?(3, 500)
      errors.add(:release_remark, :invalid)
    end
  end
end
