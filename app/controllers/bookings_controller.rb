class BookingsController < ApplicationController
  include BookingReceiptRendering
  CONFIRMATION_LIFETIME = 30.minutes

  before_action :disable_receipt_caching
  before_action :limit_public_requests

  def new
    session.delete(:booking_receipt)
    @booking = BookingRequest.new(booking_date: Date.current, dock_number: 1, request_id: SecureRandom.uuid)
    prepare_availability
  end

  def create
    @booking = BookingRequest.new(booking_params.to_h.symbolize_keys)
    @booking.booking_date = selected_date if params.key?(:selected_date)
    if params.key?(:selected_date) || params[:intent] == "availability"
      prepare_availability
      render :new
    elsif (booking = CreateBooking.call(@booking))
      flash.delete(:booking_confirmation)
      session[:booking_receipt] = { "booking_id" => booking.id, "expires_at" => (Time.current + CONFIRMATION_LIFETIME).to_i }
      redirect_to booking_confirmation_path, status: :see_other
    else
      prepare_availability
      render :new, status: (@booking.errors.any? { |error| error.type == :conflict } ? :conflict : :unprocessable_entity)
    end
  end

  def confirmation
    context = session[:booking_receipt]
    if context.is_a?(Hash) && context["expires_at"].is_a?(Integer) && context["expires_at"] > Time.current.to_i && context["booking_id"].is_a?(Integer)
      @booking = Booking.find_by(id: context["booking_id"])
    end
    unless @booking
      session.delete(:booking_receipt)
      return request.format.html? ? redirect_to(new_booking_path) : head(:not_found)
    end
    render_booking_receipt("bookings/confirmation")
  rescue ActiveRecord::ActiveRecordError
    render plain: "Não foi possível consultar o comprovante. Tente novamente.", status: :service_unavailable
  end

  private

  def limit_public_requests
    kind = if action_name != "create"
      :read
    elsif params.key?(:selected_date) || params[:intent] == "availability"
      :availability
    else
      :create
    end
    return if PublicRequestLimiter.allow?(ip: request.remote_ip, kind: kind)
    response.headers["Retry-After"] = "60"
    render plain: "Muitas solicitações. Aguarde um minuto e tente novamente.", status: :too_many_requests
  rescue ActiveRecord::ActiveRecordError
    render plain: "Serviço temporariamente indisponível. Tente novamente.", status: :service_unavailable
  end

  def disable_receipt_caching
    response.headers["Cache-Control"] = "no-store"
  end

  def selected_date
    Date.iso8601(params[:selected_date].to_s)
  rescue Date::Error
    nil
  end

  def booking_params
    params.require(:booking).permit(*BookingRequest::FIELDS)
  end

  def prepare_availability
    response.headers["Cache-Control"] = "no-store"
    @dates = (Date.current..Date.current + 2).to_a
    @availability = BookingAvailability.new(date: @booking.booking_date, dock_number: @booking.dock_number)
    @booking.slot_number = nil unless @availability.available?(@booking.slot_number.to_i)
  rescue ActiveRecord::ActiveRecordError
    @availability = nil
    @dates ||= (Date.current..Date.current + 2).to_a
    @booking.slot_number = nil
    @booking.errors.add(:base, "Não foi possível consultar os horários. Atualize antes de confirmar.")
  end
end
