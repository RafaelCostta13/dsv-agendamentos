class BookingRequest
  include ActiveModel::Model

  FIELDS = %i[contact_name company operation invoice plate vehicle_model booking_date dock_number slot_number request_id].freeze
  attr_accessor(*FIELDS)

  validates :contact_name, length: { in: 2..80, message: "Informe seu nome com 2 a 80 caracteres." }
  validates :company, length: { in: 2..100, message: "Informe a empresa com 2 a 100 caracteres." }
  validates :vehicle_model, length: { in: 2..80, message: "Informe o modelo com 2 a 80 caracteres." }
  validates :invoice, format: { with: /\A[0-9]{1,44}\z/, message: "Informe uma nota fiscal com 1 a 44 dígitos." }
  validates :plate, format: { with: /\A[A-Z]{3}[0-9][A-Z0-9][0-9]{2}\z/, message: "Informe uma placa válida." }
  validates :operation, inclusion: { in: Booking::OPERATIONS, message: "Selecione o tipo de operação." }
  validates :dock_number, numericality: { only_integer: true, in: AgendaDefinition::DOCK_NUMBERS, message: "Selecione uma doca válida." }
  validates :slot_number, numericality: { only_integer: true, in: AgendaDefinition::SLOT_NUMBERS, message: "Selecione um horário válido." }
  validates :request_id, format: { with: /\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/, message: "A tentativa é inválida. Inicie um novo agendamento." }
  validates :booking_date, presence: { message: "Selecione uma data válida." }
  validate :permitted_schedule, on: :new_booking
  validate :dock_matches_operation

  def initialize(attributes = {})
    super
    %i[contact_name company vehicle_model invoice operation].each do |field|
      public_send("#{field}=", public_send(field).to_s.strip)
    end
    self.plate = plate.to_s.upcase.gsub(/[[:space:]-]/, "")
    self.request_id = request_id.to_s.downcase
    self.booking_date = Date.iso8601(booking_date.to_s)
  rescue Date::Error
    self.booking_date = nil
  end

  def booking_attributes
    FIELDS.index_with { |field| public_send(field) }.merge(
      dock_number: dock_number.to_i, slot_number: slot_number.to_i
    )
  end

  private

  def permitted_schedule
    now = Time.current
    unless AgendaDefinition.permitted_date?(booking_date, now: now)
      errors.add(:booking_date, "Agende para hoje ou para um dos próximos dois dias.")
      return
    end
    return unless AgendaDefinition::SLOT_NUMBERS.cover?(slot_number.to_i)

    unless AgendaDefinition.future_slot?(booking_date, slot_number.to_i, now: now)
      errors.add(:slot_number, "Selecione um horário que ainda não começou.")
    end
  end

  def dock_matches_operation
    return if AgendaDefinition.dock_numbers_for(operation).include?(dock_number.to_i)

    errors.add(:dock_number, "Selecione uma doca disponível para esta operação.")
  end
end
