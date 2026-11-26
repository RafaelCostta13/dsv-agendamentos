class BookingChangeRequest
  include ActiveModel::Model

  FIELDS = %i[booking_date dock_number slot_number change_reason lock_version].freeze
  attr_accessor(*FIELDS)

  validates :change_reason, length: { in: 3..500, message: "Informe um motivo contendo entre 3 e 500 caracteres." }
  validates :dock_number, numericality: { only_integer: true, in: AgendaDefinition::DOCK_NUMBERS, message: "Selecione uma doca válida." }, on: :reschedule
  validates :slot_number, numericality: { only_integer: true, in: AgendaDefinition::SLOT_NUMBERS, message: "Selecione uma janela válida." }, on: :reschedule
  validate :permitted_position, on: :reschedule

  def initialize(attributes = {})
    super
    self.change_reason = change_reason.to_s.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
    self.lock_version = lock_version.to_s
    self.booking_date = parse_date(booking_date)
  end

  def position
    dock = Integer(dock_number.to_s, 10, exception: false)
    slot = Integer(slot_number.to_s, 10, exception: false)
    return unless booking_date && AgendaDefinition::DOCK_NUMBERS.cover?(dock) && AgendaDefinition::SLOT_NUMBERS.cover?(slot)

    { date: booking_date, dock_number: dock, slot_number: slot }
  end

  def booking_changes
    { booking_date: booking_date, dock_number: position.fetch(:dock_number), slot_number: position.fetch(:slot_number), change_reason: change_reason }
  end

  private

  def parse_date(value)
    text = value.to_s
    return unless text.match?(/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/)

    date = Date.iso8601(text)
    date if date.year.between?(1, 9999)
  rescue Date::Error
    nil
  end

  def permitted_position
    now = Time.current
    unless AgendaDefinition.permitted_date?(booking_date, now: now)
      errors.add(:booking_date, "Selecione uma data dentro do período permitido para agendamento.")
      return
    end
    slot = Integer(slot_number.to_s, 10, exception: false)
    return unless AgendaDefinition::SLOT_NUMBERS.cover?(slot)

    unless AgendaDefinition.future_slot?(booking_date, slot, now: now)
      errors.add(:slot_number, "Selecione um horário que ainda não começou.")
    end
  end
end
