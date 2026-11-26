module BookingData
  private

  def booking_attributes(overrides = {})
    {
      protocol: "RF002-#{SecureRandom.hex(10)}",
      request_id: SecureRandom.uuid,
      booking_date: Date.new(2026, 11, 25),
      dock_number: 1,
      slot_number: 1,
      operation: "entrega",
      contact_name: "Responsável de teste",
      company: "Empresa de teste",
      invoice: "000123456",
      plate: "ABC1D23",
      vehicle_model: "Caminhão"
    }.merge(overrides)
  end

  def insert_booking(overrides = {})
    Booking.insert_all!([ booking_attributes(overrides) ]).rows.first.first
  end

  def assert_database_rejects(error, model, attributes)
    failure = assert_raises(error) do
      model.transaction(requires_new: true) do
        connection = model.connection
        values = { created_at: Time.current }
        values[:updated_at] = Time.current if model.column_names.include?("updated_at")
        values.merge!(attributes)
        columns = values.keys.map { |name| connection.quote_column_name(name) }.join(", ")
        placeholders = values.keys.each_index.map { |index| "$#{index + 1}" }.join(", ")
        # Plain bound types bypass model coercions, notably nil lock_version becoming zero.
        binds = values.map do |name, value|
          ActiveRecord::Relation::QueryAttribute.new(name.to_s, value, ActiveRecord::Type::Value.new)
        end
        connection.exec_query(
          "INSERT INTO #{connection.quote_table_name(model.table_name)} (#{columns}) VALUES (#{placeholders})",
          "RF002 constraint test", binds
        )
      end
    end
    assert_kind_of PG::CheckViolation, failure.cause if error == ActiveRecord::StatementInvalid
  end
end
