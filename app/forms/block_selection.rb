class BlockSelection
  include ActiveModel::Model
  attr_accessor :blocked_date, :dock_numbers, :slot_numbers, :reason

  validates :reason, length: { maximum: 250, message: "O motivo deve ter no máximo 250 caracteres." }, allow_nil: true
  validate :valid_selections
  validate :valid_schedule

  def initialize(attributes = {})
    super
    self.blocked_date = parse_date(blocked_date)
    self.reason = reason.to_s.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "").presence
    @invalid_docks, self.dock_numbers = normalize(dock_numbers, AgendaDefinition::DOCK_NUMBERS)
    @invalid_slots, self.slot_numbers = normalize(slot_numbers, AgendaDefinition::SLOT_NUMBERS)
  end

  def eligible_slots(now: Time.current)
    AgendaDefinition::SLOT_NUMBERS.select { |slot| AgendaDefinition.future_slot?(blocked_date, slot, now: now) }
  end

  def positions
    dock_numbers.product(slot_numbers).map { |dock, slot| { date: blocked_date, dock_number: dock, slot_number: slot } }
  end

  private

  def normalize(values, range)
    return [ true, [] ] unless values.nil? || (values.is_a?(Array) && values.size <= 80)

    values ||= []
    numbers = values.map { |value| value.to_s.match?(/\A[0-9]{1,2}\z/) ? Integer(value.to_s, 10) : nil }
    [ numbers.any? { |number| !range.cover?(number) }, numbers.compact.select { |number| range.cover?(number) }.uniq.sort ]
  end

  def parse_date(value)
    return unless value.to_s.match?(/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/)

    date = Date.iso8601(value.to_s)
    date if date.year.between?(1, 9999)
  rescue Date::Error
    nil
  end

  def valid_selections
    errors.add(:dock_numbers, "Selecione pelo menos uma doca válida.") if @invalid_docks || dock_numbers.empty?
    errors.add(:slot_numbers, "Selecione pelo menos um horário válido.") if @invalid_slots || slot_numbers.empty?
  end

  def valid_schedule
    now = Time.current
    unless AgendaDefinition.permitted_date?(blocked_date, now: now)
      errors.add(:blocked_date, "Selecione uma data dentro do período permitido.")
      return
    end
    if slot_numbers.any? { |slot| !AgendaDefinition.future_slot?(blocked_date, slot, now: now) }
      errors.add(:slot_numbers, "Uma ou mais janelas selecionadas não estão disponíveis para bloqueio.")
    end
  end
end
