class BookingCheckinPolicy
  MESSAGES = {
    status: "O estado atual do agendamento não permite realizar esta operação.",
    date: "O check-in somente pode ser realizado na data do agendamento.",
    early: "O horário agendado ainda não foi iniciado.",
    cutoff: "O horário limite para check-in é 17:30.",
    occupied: "Esta doca já está ocupada por outro veículo. Aguarde a liberação antes de registrar um novo check-in."
  }.freeze

  def self.reason(booking, now: Time.current)
    return :status unless booking.status == "agendado"
    return :date unless booking.booking_date == now.to_date
    return :early if now < AgendaDefinition.slot_start(booking.booking_date, booking.slot_number)
    return :cutoff if now >= AgendaDefinition.checkin_cutoff(now.to_date)
    return :occupied if Booking.where(dock_number: booking.dock_number, status: "em_operacao").where.not(id: booking.id).exists?

    nil
  end
end
