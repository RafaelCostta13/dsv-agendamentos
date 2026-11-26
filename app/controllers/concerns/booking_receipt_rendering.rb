module BookingReceiptRendering
  private

  def render_booking_receipt(template)
    response.headers["Cache-Control"] = "no-store"
    if request.format.png?
      return head :not_found unless @booking.status == "agendado"

      send_data ReceiptQrCode.new(@booking).png, type: "image/png", disposition: "inline", filename: "comprovante.png"
    elsif request.format.html?
      render template
    else
      head :not_acceptable
    end
  end
end
