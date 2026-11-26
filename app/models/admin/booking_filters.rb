module Admin
  class BookingFilters
    include ActiveModel::Model

    attr_accessor :date, :dock_number, :operation, :status, :start_date, :end_date

    validates :dock_number, inclusion: { in: AgendaDefinition::DOCK_NUMBERS.map(&:to_s), message: "Selecione uma doca válida." }, allow_blank: true
    validates :operation, inclusion: { in: Booking::OPERATIONS, message: "Selecione uma operação válida." }, allow_blank: true
    validates :status, inclusion: { in: Booking::STATUSES, message: "Selecione um status válido." }, allow_blank: true
    validate :valid_date

    def parsed_date
      parse_date(date)
    end

    def period?
      start_date.present? || end_date.present?
    end

    def scope
      return Booking.none unless valid?

      records = Booking.all
      if period?
        records = records.where(booking_date: parse_date(start_date)..) if start_date.present?
        records = records.where(booking_date: ..parse_date(end_date)) if end_date.present?
      elsif date.present?
        records = records.where(booking_date: parsed_date)
      end
      records = records.where(dock_number: dock_number) if dock_number.present?
      records = records.where(operation: operation) if operation.present?
      records = records.where(status: status) if status.present?
      records
    end

    def query_parameters
      { date: period? ? nil : date, start_date: start_date, end_date: end_date, dock_number: dock_number, operation: operation, status: status }.select { |_, value| value.present? }
    end

    private

    def parse_date(value)
      return unless value.to_s.match?(/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/)
      parsed = Date.iso8601(value)
      parsed if parsed.year.between?(1, 9999)
    rescue Date::Error
      nil
    end

    def valid_date
      errors.add(:base, "Informe uma data inicial válida no formato AAAA-MM-DD.") if start_date.present? && !parse_date(start_date)
      errors.add(:base, "Informe uma data final válida no formato AAAA-MM-DD.") if end_date.present? && !parse_date(end_date)
      if parse_date(start_date) && parse_date(end_date) && parse_date(start_date) > parse_date(end_date)
        errors.add(:base, "A data inicial deve ser menor ou igual à data final.")
      end
      errors.add(:date, "Informe uma data válida no formato AAAA-MM-DD.") if date.present? && parsed_date.nil?
    end
  end
end
