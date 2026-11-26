require "test_helper"
require_relative "../support/booking_data"
require_relative "../support/xlsx_reader"

class ExportBookingsXlsxTest < ActiveSupport::TestCase
  include BookingData
  include XlsxReader

  test "a real XLSX reader sees the twenty six columns native dates times numbers and intact invoice text" do
    travel_to Time.zone.local(2026, 11, 25, 14) do
      invoice="0"+"1"*43
      record=Booking.create!(booking_attributes(booking_date: Date.current, slot_number: 3, status: "liberado",
        checkin_at: Time.zone.local(2026, 11, 25, 10, 5), released_at: Time.zone.local(2026, 11, 25, 10, 48), release_remark: "Conferência concluída", invoice: invoice))
      export=ExportBookingsXlsx.new(Admin::BookingFilters.new)
      bytes=export.call
      with_xlsx(bytes) do |book|
        assert_equal [ "Agendamentos" ], book.sheets
        assert_equal ExportBookingsXlsx::HEADERS, book.row(1)
        assert_equal 2, book.last_row
        assert_equal 26, book.last_column
        assert_equal record.protocol, book.cell(2, 1)
        assert_equal invoice, book.cell(2, 7)
        assert_equal :string, book.celltype(2, 7)
        assert_equal Date.current, book.cell(2, 2)
        assert_equal :date, book.celltype(2, 2)
        assert_equal 14*3600, book.cell(2, 3)
        assert_equal :time, book.celltype(2, 3)
        assert_equal 10*3600, book.cell(2, 13)
        assert_equal 1, book.cell(2, 11)
        assert_equal [ 43.0, 5.0, 0.0 ], (20..22).map { |col| book.cell(2, col) }
        assert_equal "Liberado", book.cell(2, 15)
      end
      xml=xlsx_xml(bytes)
      assert_equal "A1:Z2", xml.at_xpath("//autoFilter")["ref"]
      assert_equal "frozen", xml.at_xpath("//pane")["state"]
      assert_equal "A2", xml.at_xpath("//pane")["topLeftCell"]
      assert_empty xml.xpath("//mergeCells|//f|//hyperlink")
      styles=xlsx_xml(bytes, "xl/styles.xml")
      assert styles.xpath("//numFmt").any? { |style| style["formatCode"]=="0.00" }
      assert_equal "agendamentos_completo_2026-11-25.xlsx", export.filename
      File.binwrite(Rails.root.join("tmp/rf012-example.xlsx"), bytes)
    end
  end

  test "all untrusted text including whitespace DDE and hyperlink syntax remains literal without formulas or relationships" do
    values=[ "=1+1", "+123456", "-1+1", "@SUM(A1:A2)", "\t=HYPERLINK(\"https://example.invalid\")", "  =cmd|' /C calc'!A0", "\n=1+1" ]
    values.each_with_index do |value, index|
      Booking.create!(booking_attributes(protocol: "DA-SAFE-#{index}", company: value, contact_name: value, vehicle_model: value, slot_number: index+1,
        change_reason: value, release_remark: value, invoice: "000012345678"))
    end
    bytes=ExportBookingsXlsx.new(Admin::BookingFilters.new).call
    with_xlsx(bytes) do |book|
      values.each_with_index do |value, index|
        [ 4, 5, 9, 23, 24 ].each do |column|
          assert_equal value, book.cell(index+2, column)
          assert_equal :string, book.celltype(index+2, column)
        end
      end
    end
    assert_empty xlsx_xml(bytes).xpath("//f|//hyperlinks")
    Zip::File.open_buffer(bytes) do |zip|
      assert_empty zip.entries.select { |entry| entry.name.include?("externalLinks") }
    end
  end

  test "missing values remain blank and every existing state is exported with its persisted current position" do
    %w[agendado em_operacao liberado cancelado reagendamento].each_with_index do |status, index|
      Booking.create!(booking_attributes(slot_number: index+1, status: status,
        checkin_at: status.in?(%w[em_operacao liberado]) ? Time.zone.local(2026, 11, 25, 9) : nil,
        released_at: status=="liberado" ? Time.zone.local(2026, 11, 25, 9, 30) : nil, release_remark: status=="liberado" ? "Conferido" : nil))
    end
    bytes=ExportBookingsXlsx.new(Admin::BookingFilters.new).call
    with_xlsx(bytes) do |book|
      assert_equal 6, book.last_row
      assert_equal [ "Agendado", "Em operação", "Liberado", "Cancelado", "Reagendamento obrigatório" ], (2..6).map { |row| book.cell(row, 15) }
      [ 16, 17, 18, 19, 20, 21, 22, 23, 24 ].each { |column| assert_nil book.cell(2, column) }
      assert_nil book.cell(3, 20)
      assert_nil book.cell(3, 22)
    end
  end

  test "metrics use full timestamps Sao Paulo rollover fractional minutes and the last window" do
    export=ExportBookingsXlsx.new(Admin::BookingFilters.new)
    record=Booking.new(booking_attributes(booking_date: Date.new(2026, 11, 25), slot_number: 10, created_at: Time.utc(2026, 11, 26, 2, 59, 59), updated_at: Time.utc(2026, 11, 26, 3), checkin_at: Time.zone.local(2026, 11, 25, 17, 20), released_at: Time.zone.local(2026, 11, 26, 0, 20)))
    row=export.row(record)
    assert_equal [ 420.0, 20.0, 392.0 ], row[19, 3]
    assert_equal (Date.new(2026, 11, 25)-ExportBookingsXlsx::EPOCH).to_i, row[1]
    assert_in_delta 86399.0/86400, row[2], 0.0000001
    assert_equal (Date.new(2026, 11, 26)-ExportBookingsXlsx::EPOCH).to_i, row[24]
    assert_equal 0.0, row[25]
    assert_in_delta (17*3600+48*60)/86400.0, row[13], 0.0000001
    record.checkin_at=Time.zone.local(2026, 11, 25, 16, 59, 59)
    record.released_at=Time.zone.local(2026, 11, 25, 17, 0, 1)
    assert_equal [ 0.03, 0, 0 ], export.row(record)[19, 3]
    record.released_at=record.checkin_at-1.second
    assert_nil export.row(record)[19]
    record.released_at=nil
    assert_nil export.row(record)[19]
    assert_nil export.row(record)[21]
  end

  test "empty and excessive exports are rejected without silent truncation and exact limit works" do
    assert_raises(ExportBookingsXlsx::Rejected) { ExportBookingsXlsx.new(Admin::BookingFilters.new).call }
    stub_const(ExportBookingsXlsx, :LIMIT, 3) do
      3.times { |i| Booking.create!(booking_attributes(slot_number: i+1)) }
      export=ExportBookingsXlsx.new(Admin::BookingFilters.new)
      with_xlsx(export.call) { |book| assert_equal 4, book.last_row }
      Booking.create!(booking_attributes(slot_number: 4))
      assert_raises(ExportBookingsXlsx::Rejected) { ExportBookingsXlsx.new(Admin::BookingFilters.new).call }
    end
  end

  private

  def stub_const(owner, name, value)
    previous=owner.const_get(name)
    owner.send(:remove_const, name)
    owner.const_set(name, value)
    yield
  ensure
    owner.send(:remove_const, name)
    owner.const_set(name, previous)
  end
end
