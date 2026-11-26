module Admin
  module AuditEventsHelper
    AUDIT_EVENTS = {
      "user_created" => [ "Usuário cadastrado", "♙", "blue", "Criação de conta administrativa." ],
      "user_updated" => [ "Dados cadastrais alterados", "✎", "blue", "Atualização cadastral do usuário." ],
      "user_role_changed" => [ "Perfil de acesso alterado", "↻", "attention", "Alteração do perfil cadastrado." ],
      "user_activated" => [ "Usuário ativado", "✓", "success", "Reativação da conta." ],
      "user_deactivated" => [ "Usuário desativado", "×", "danger", "Desativação da conta." ],
      "user_password_reset" => [ "Senha redefinida", "↻", "attention", "Redefinição administrativa, sem registro de credenciais." ],
      "password_changed" => [ "Senha própria alterada", "✓", "success", "Alteração segura da senha da própria conta." ],
      "login_success" => [ "Login realizado", "→", "success", "Autenticação administrativa concluída." ],
      "logout" => [ "Logout realizado", "←", "neutral", "Sessão administrativa encerrada." ],
      "booking_exported" => [ "Planilha gerada", "⇩", "blue", "Exportação administrativa de agendamentos." ],
      "create" => [ "Agendamento criado", "▦", "blue", "Registro inicial do agendamento." ],
      "reschedule" => [ "Alteração / Reagendamento", "↻", "attention", "Atualização da posição reservada." ],
      "cancel" => [ "Agendamento cancelado", "×", "danger", "Cancelamento da reserva." ],
      "checkin" => [ "Check-in realizado", "→", "attention", "Registro da entrada do veículo." ],
      "release" => [ "Veículo liberado", "✓", "success", "Registro da saída do veículo." ],
      "no_show" => [ "Reagendamento obrigatório por não comparecimento", "!", "danger", "Fechamento automático por não comparecimento." ],
      "block" => [ "Posição bloqueada", "▣", "neutral", "Indisponibilidade operacional registrada." ],
      "unblock" => [ "Posição desbloqueada", "□", "success", "Remoção do bloqueio operacional." ]
    }.freeze
    AUDIT_FIELDS = {
      "protocol" => "Protocolo", "operation" => "Operação", "booking_date" => "Data agendada", "blocked_date" => "Data bloqueada",
      "dock_number" => "Doca", "slot_number" => "Horário", "status" => "Status", "checkin_at" => "Horário de check-in",
      "released_at" => "Horário de liberação", "release_remark" => "Observação da liberação",
      "change_reason" => "Motivo da alteração", "reason" => "Motivo"
    }.freeze

    USER_AUDIT_FIELDS = { "name"=>"Nome", "email"=>"E-mail", "role"=>"Perfil", "active"=>"Estado", "must_change_password"=>"Troca de senha obrigatória", "password_changed_at"=>"Senha definida em", "deactivated_at"=>"Desativado em" }.freeze

    def audit_snapshot(value)
      value.is_a?(Hash) ? value : {}
    end

    def audit_metadata(event)
      AUDIT_EVENTS.fetch(event.action, [ "Evento não reconhecido", "?", "neutral", "Informações históricas disponíveis abaixo." ])
    end

    def audit_label(event)
      return audit_metadata(event).first unless event.action == "reschedule" && event.entity_type == "Booking"
      before = audit_snapshot(event.previous_values)["status"]
      after = audit_snapshot(event.new_values)["status"]
      return "Veículo reagendado" if before == "reagendamento" && after == "agendado"
      return "Agendamento alterado" if before == "agendado" && after == "agendado"
      audit_metadata(event).first
    end

    def audit_origin(event)
      return { "public_form"=>"Formulário público", "authenticated_user"=>"Painel administrativo", "system"=>"Sistema automático", "bootstrap"=>"Inicialização interna", "unknown"=>"Origem não registrada" }.fetch(event.origin) if event.origin.present?
      before, after = audit_snapshot(event.previous_values), audit_snapshot(event.new_values)
      if event.entity_type == "User" && event.action.start_with?("user_") && AUDIT_EVENTS.key?(event.action)
        return event.action == "user_created" && event.reason == "Inicialização interna do administrador." ? "Inicialização interna" : "Painel administrativo"
      end
      if event.entity_type == "Booking"
        return "Formulário público" if event.action == "create" && after["protocol"].present? && after["status"] == "agendado"
        return "Sistema automático" if event.action == "no_show" && event.reason == ProcessNoShows::REASON && before["status"] == "agendado" && after["status"] == "reagendamento"
        if %w[reschedule cancel checkin release].include?(event.action) && before["status"].present? && after["status"].present?
          return "Painel administrativo"
        end
      elsif event.entity_type == "SlotBlock" && %w[block unblock].include?(event.action)
        values = event.action == "block" ? after : before
        return "Painel administrativo" if %w[blocked_date dock_number slot_number].all? { |key| values[key].present? }
      end
      "Origem não registrada"
    end

    def audit_actor(event)
      return "#{event.actor_name} · #{User::ROLES.fetch(event.actor_role, event.actor_role)}" if event.actor_name.present? && event.actor_role.present?
      return "Sistema automático" if event.origin == "system"
      "Responsável não registrado"
    end

    def audit_entity(event)
      { "Booking"=>"Agendamento", "SlotBlock"=>"Bloqueio", "User"=>"Usuário" }.fetch(event.entity_type, "Entidade não reconhecida")
    end

    def audit_reference(event, booking = nil, user = nil)
      before, after = audit_snapshot(event.previous_values), audit_snapshot(event.new_values)
      if event.entity_type == "Booking"
        protocol = after["protocol"].presence || before["protocol"].presence || booking&.protocol
        protocol.is_a?(String) ? protocol : "Agendamento não disponível"
      elsif event.entity_type == "User"
        name = after["name"].presence || before["name"].presence || user&.name
        email = after["email"].presence || before["email"].presence || user&.email
        [ name, email ].select { |value| value.is_a?(String) }.presence&.join(" · ") || "Usuário não disponível"
      elsif event.entity_type == "SlotBlock"
        values = event.action == "unblock" ? before : after
        "#{audit_value('blocked_date', values['blocked_date'])} · Doca #{audit_value('dock_number', values['dock_number'])} · #{audit_value('slot_number', values['slot_number'])}"
      else
        "Referência não registrada"
      end
    end

    def audit_rows(event)
      before, after = audit_snapshot(event.previous_values), audit_snapshot(event.new_values)
      fields = event.entity_type == "User" ? USER_AUDIT_FIELDS : AUDIT_FIELDS
      fields.keys.select { |key| before.key?(key) || after.key?(key) }.map do |key|
        { label: fields.fetch(key), before: audit_value(key, before[key]), after: audit_value(key, after[key]), changed: before[key] != after[key] }
      end
    end

    def audit_value(key, value)
      return "Não registrado" if value.nil? || value == ""
      case key
      when "booking_date", "blocked_date"
        value.is_a?(String) && value.match?(/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/) ? l(Date.iso8601(value)) : "Valor histórico não reconhecido"
      when "checkin_at", "released_at", "password_changed_at", "deactivated_at"
        value.is_a?(String) ? l(Time.iso8601(value).in_time_zone) : "Valor histórico não reconhecido"
      when "dock_number", "slot_number"
        number = value.to_s.match?(/\A[0-9]{1,2}\z/) ? Integer(value.to_s, 10) : nil
        if key == "dock_number" && AgendaDefinition::DOCK_NUMBERS.cover?(number)
          "%02d" % number
        elsif key == "slot_number" && AgendaDefinition::SLOT_NUMBERS.cover?(number)
          AgendaDefinition::SLOT_WINDOWS.fetch(number).join(" - ")
        else
          "Valor histórico não reconhecido"
        end
      when "role" then User::ROLES.fetch(value, "Valor histórico não reconhecido")
      when "active" then value == true ? "Ativo" : value == false ? "Inativo" : "Valor histórico não reconhecido"
      when "must_change_password" then value == true ? "Sim" : value == false ? "Não" : "Valor histórico não reconhecido"
      when "status" then Admin::PanelHelper::STATES.fetch(value, "Valor histórico não reconhecido")
      when "operation" then { "entrega"=>"Entrega", "coleta"=>"Coleta" }.fetch(value, "Valor histórico não reconhecido")
      else value.is_a?(String) ? value : "Valor histórico não reconhecido"
      end
    rescue ArgumentError, TypeError
      "Valor histórico não reconhecido"
    end
  end
end
