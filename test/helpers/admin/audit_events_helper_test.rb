require "test_helper"

class Admin::AuditEventsHelperTest < ActionView::TestCase
  include Admin::AuditEventsHelper

  test "known events distinguish alteration from rescheduling using snapshots only" do
    event = AuditEvent.new(entity_type: "Booking", action: "reschedule", previous_values: { status: "agendado" }, new_values: { status: "agendado" })
    assert_equal "Agendamento alterado", audit_label(event)
    event.previous_values = { status: "reagendamento" }
    assert_equal "Veículo reagendado", audit_label(event)
    event.previous_values = nil
    assert_equal "Alteração / Reagendamento", audit_label(event)
    assert_equal "Origem não registrada", audit_origin(event)
    event.action = "unknown"
    assert_equal "Evento não reconhecido", audit_label(event)
  end

  test "whitelisted comparison formats history and does not fill absent fields with current values" do
    event = AuditEvent.new(previous_values: { booking_date: "2026-11-25", dock_number: 1, slot_number: 1, status: "agendado" },
      new_values: { booking_date: "2026-11-27", dock_number: 8, slot_number: 10, status: "agendado", lock_version: 8, company: "Private", token: "Secret" })
    rows = audit_rows(event)
    assert_equal 4, rows.size
    assert_equal [ "25/11/2026", "01", "08:00 - 09:00", "Agendado" ], rows.map { |row| row[:before] }
    assert_equal [ "27/11/2026", "08", "17:00 - 17:48", "Agendado" ], rows.map { |row| row[:after] }
    assert_equal [ true, true, true, false ], rows.map { |row| row[:changed] }
    event.previous_values = nil
    assert audit_rows(event).all? { |row| row[:before] == "Não registrado" }
  end

  test "malformed JSON and values do not raise or render unknown sensitive fields" do
    event = AuditEvent.new(previous_values: [ "not a snapshot" ], new_values: "bad")
    assert_empty audit_rows(event)
    %w[booking_date blocked_date dock_number slot_number status checkin_at released_at reason].each do |key|
      assert_equal "Valor histórico não reconhecido", audit_value(key, { secret: "hidden" })
    end
    assert_equal "Não registrado", audit_value("status", nil)
    assert_equal "Valor histórico não reconhecido", audit_value("booking_date", "invalid")
    assert_equal "Valor histórico não reconhecido", audit_value("checkin_at", "invalid")
  end
end
