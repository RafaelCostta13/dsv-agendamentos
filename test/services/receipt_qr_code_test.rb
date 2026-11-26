require "test_helper"
require "open3"
require "tempfile"
require_relative "../support/booking_data"

class ReceiptQrCodeTest < ActiveSupport::TestCase
  include BookingData

  test "PNG effectively decodes to operational text and excludes personal and internal information" do
    record = Booking.create!(booking_attributes(booking_date: Date.new(2026, 11, 26), dock_number: 3, slot_number: 3))
    generator = ReceiptQrCode.new(record)
    expected = "DESTINO: DSV\nSISTEMA: DOCA AGENDA\nPROTOCOLO: #{record.protocol}\nOPERACAO: ENTREGA\nDATA: 26/11/2026\nDOCA: 03\nHORARIO: 10:00 - 11:00\nFUSO: HORARIO DE BRASILIA"
    assert_equal expected, generator.text
    assert_equal generator.png, generator.png
    image = ChunkyPNG::Image.from_blob(generator.png)
    assert_equal image.width, image.height
    assert_equal ChunkyPNG::Color::WHITE, image[0, 0]
    [ 180, 220, 240 ].each do |size|
      rendered = image.resample_nearest_neighbor(size, size)
      assert_equal expected, decode(rendered.to_blob)
    end
    %i[contact_name company invoice plate vehicle_model request_id].each { |field| assert_not_includes generator.text, record.public_send(field) }
    refute_match(/https?:|ID:|TOKEN:|<script/i, generator.text)
  end

  test "last window and collection use current persisted data after administrative movement" do
    travel_to Time.zone.local(2026, 11, 25, 7) do
      record=Booking.create!(booking_attributes(operation: "coleta", booking_date: Date.current+1))
      old=ReceiptQrCode.new(record).text
      form=BookingChangeRequest.new(booking_date: Date.current+2, dock_number: 8, slot_number: 10, lock_version: 0, change_reason: "Nova posição")
      assert ChangeBooking.new(booking_id: record.id, action: "reschedule", form: form).call
      qr=ReceiptQrCode.new(record.reload)
      assert_includes qr.text, "OPERACAO: COLETA"
      assert_includes qr.text, "DATA: 27/11/2026"
      assert_includes qr.text, "DOCA: 08"
      assert_includes qr.text, "HORARIO: 17:00 - 17:48"
      assert_not_equal old, qr.text
      assert_equal qr.text, decode(qr.png)
    end
  end

  test "only persisted scheduled records can generate QR codes and protocol text cannot inject fields" do
    assert_raises(ArgumentError) { ReceiptQrCode.new(Booking.new(booking_attributes)) }
    %w[cancelado reagendamento em_operacao liberado].each_with_index do |status, index|
      record=Booking.create!(booking_attributes(status: status, slot_number: index+1, checkin_at: Time.current, released_at: Time.current, release_remark: "Conferido"))
      assert_raises(ArgumentError) { ReceiptQrCode.new(record) }
    end
    record=Booking.create!(booking_attributes(slot_number: 10, protocol: "DA-TEST\nTOKEN: forged"))
    assert_equal 8, ReceiptQrCode.new(record).text.lines.size
  end

  private

  def decode(png)
    Tempfile.create([ "receipt-qr", ".png" ]) do |file|
      file.binmode
      file.write(png)
      file.flush
      result, status=Open3.capture2e(ENV.fetch("ZBARIMG_BIN", "zbarimg"), "--quiet", "--raw", "--nodbus", file.path)
      assert status.success?, result
      result.sub(/\n\z/, "")
    end
  end
end
