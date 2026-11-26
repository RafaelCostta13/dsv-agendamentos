module Admin
  class AuditFilters
    include ActiveModel::Model
    attr_accessor :start_date, :end_date, :event, :entity_type, :booking_protocol, :actor_user_id
    ACTIONS = %w[create reschedule cancel checkin release no_show block unblock user_created user_updated user_role_changed user_activated user_deactivated user_password_reset password_changed login_success logout booking_exported].freeze
    validates :event, inclusion: { in: ACTIONS, message: "Selecione um evento válido." }, allow_blank: true
    validates :entity_type, inclusion: { in: AuditEvent::ENTITY_TYPES, message: "Selecione uma entidade válida." }, allow_blank: true
    validates :booking_protocol, length: { maximum: 50, message: "Informe um protocolo com até 50 caracteres." }
    validate :valid_period
    validates :actor_user_id, format: { with: /\A[1-9][0-9]{0,18}\z/, message: "Selecione um operador válido." }, allow_blank: true

    def initialize(attributes = {})
      super
      self.booking_protocol = booking_protocol.to_s.strip.upcase
    end

    def query_parameters
      { start_date: start_date, end_date: end_date, event: event, entity_type: entity_type, booking_protocol: booking_protocol, actor_user_id: actor_user_id }.select { |_, value| value.present? }
    end

    def scope
      return AuditEvent.none unless valid?

      records = AuditEvent.all
      records = records.where(created_at: parsed(start_date).in_time_zone..) if start_date.present?
      records = records.where(created_at: ...((parsed(end_date)+1).in_time_zone)) if end_date.present?
      records = records.where(action: event) if event.present?
      records = records.where(entity_type: entity_type) if entity_type.present?
      records = records.where(actor_user_id: actor_user_id) if actor_user_id.present?
      records = records.where(entity_type: "Booking", entity_id: Booking.where(protocol: booking_protocol).select(:id)) if booking_protocol.present?
      records
    end

    private

    def parsed(value)
      return unless value.to_s.match?(/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/)
      date = Date.iso8601(value)
      date if date.year.between?(1, 9999)
    rescue Date::Error
      nil
    end

    def valid_period
      [ start_date, end_date ].each do |value|
        errors.add(:base, "Informe datas válidas no formato AAAA-MM-DD.") if value.present? && !parsed(value)
      end
      if parsed(start_date) && parsed(end_date) && parsed(start_date) > parsed(end_date)
        errors.add(:base, "A data inicial não pode ser posterior à data final.")
      end
    end
  end
end
