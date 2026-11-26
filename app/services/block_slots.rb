class BlockSlots
  attr_reader :form, :http_status, :created_count, :existing_count, :conflicts

  def initialize(form, actor: nil)
    @form = form
    @http_status = :unprocessable_entity
    @created_count = 0
    @existing_count = 0
    @conflicts = []
    @actor = actor
  end

  def preview
    form.valid? && inspect_positions
  end

  def call
    @created_count = 0
    return false unless form.valid?

    ApplicationRecord.transaction(requires_new: true) do
      return fail_operation("Sua autorização foi alterada. Entre novamente.", :forbidden) if @actor && !User.lock.find_by(id: @actor.id, active: true)&.role.in?(%w[admin operator])
      AgendaCapacityLock.lock_positions!(form.positions)
      return false unless form.valid? && inspect_positions

      form.positions.each do |position|
        next if @existing.include?([ position[:dock_number], position[:slot_number] ])

        block = SlotBlock.create!(blocked_date: position[:date], dock_number: position[:dock_number], slot_number: position[:slot_number], reason: form.reason)
        AuditEvent.record!({ entity_type: "SlotBlock", entity_id: block.id, action: "block", reason: form.reason,
          new_values: block.attributes.slice("blocked_date", "dock_number", "slot_number", "reason") }, actor: @actor)
        @created_count += 1
      end
      true
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked
    fail_operation("A disponibilidade foi alterada durante a operação. Consulte os dados atualizados antes de continuar.", :conflict)
  rescue ActiveRecord::ActiveRecordError
    fail_operation("Não foi possível concluir o bloqueio. Nenhum novo bloqueio foi confirmado.", :service_unavailable)
  end

  def notice
    "#{created_count} posições bloqueadas com sucesso. #{existing_count} posições já estavam bloqueadas e foram preservadas."
  end

  private

  def inspect_positions
    @conflicts = Booking.where(booking_date: form.blocked_date, dock_number: form.dock_numbers, slot_number: form.slot_numbers,
      status: BookingAvailability::CAPACITY_STATUSES).order(:dock_number, :slot_number).pluck(:dock_number, :slot_number)
    @existing = SlotBlock.where(blocked_date: form.blocked_date, dock_number: form.dock_numbers, slot_number: form.slot_numbers).pluck(:dock_number, :slot_number)
    @existing_count = @existing.size
    return true if conflicts.empty?

    text = "Existem agendamentos nas posições selecionadas. Nenhum novo bloqueio foi realizado."
    text += " Há inconsistência entre reserva e bloqueio existentes." if (conflicts & @existing).any?
    fail_operation(text, :conflict)
  end

  def fail_operation(message, status)
    @created_count = 0
    @http_status = status
    form.errors.add(:base, message)
    false
  end
end
