module Admin
  module PanelHelper
    STATES = {
      "available" => "Disponível", "agendado" => "Agendado", "em_operacao" => "Em operação",
      "liberado" => "Liberado", "blocked" => "Bloqueado", "ended" => "Horário encerrado",
      "outside_horizon" => "Fora do horizonte", "inconsistent" => "Inconsistência: reserva e bloqueio",
      "cancelado" => "Cancelado", "reagendamento" => "Reagendamento obrigatório"
    }.freeze

    def admin_state_label(state)
      STATES.fetch(state)
    end

    def admin_booking_status(booking)
      return "Em operação — Horário excedido" if booking.operation_overdue?
      return "Agendado — Chegada atrasada" if booking.late_arrival?

      admin_state_label(booking.status)
    end

    def admin_operation_label(operation)
      { "entrega" => "Entrega", "coleta" => "Coleta" }.fetch(operation)
    end

    def admin_window(slot)
      AgendaDefinition::SLOT_WINDOWS.fetch(slot)
    end

    def admin_recorded(value)
      return "Não registrado" if value.blank?

      value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone) ? l(value.in_time_zone) : value
    end
  end
end
