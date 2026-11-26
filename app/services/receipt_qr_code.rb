class ReceiptQrCode
  def initialize(booking)
    raise ArgumentError, "Receipt requires a persisted scheduled booking" unless booking.persisted? && booking.status == "agendado"

    @booking = booking
  end

  def text
    [ "DESTINO: DSV", "SISTEMA: DOCA AGENDA", "PROTOCOLO: #{@booking.protocol.gsub(/[[:cntrl:]]/, ' ')}",
      "OPERACAO: #{@booking.operation.upcase}", "DATA: #{@booking.booking_date.strftime('%d/%m/%Y')}",
      "DOCA: #{'%02d' % @booking.dock_number}", "HORARIO: #{AgendaDefinition::SLOT_WINDOWS.fetch(@booking.slot_number).join(' - ')}",
      "FUSO: HORARIO DE BRASILIA" ].join("\n")
  end

  def png
    qr = RQRCode::QRCode.new(text, level: :m)
    qr.as_png(size: (qr.modules.length + 8) * 4, border_modules: 4, fill: "white", color: "black").to_s
  end
end
