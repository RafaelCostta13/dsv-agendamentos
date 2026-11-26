class UnblockSlots
  include ActiveModel::Model
  attr_reader :tokens, :blocks, :http_status, :removed_count, :reserved_count

  STALE_MESSAGE = "Os bloqueios foram alterados ou removidos durante a operação. Consulte os dados atualizados antes de continuar."

  def initialize(tokens:, expected_id: nil, actor: nil)
    @expected_id = expected_id
    @tokens = tokens
    @blocks = []
    @removed_count = 0
    @reserved_count = 0
    @http_status = :unprocessable_entity
    @actor = actor
    super()
  end

  def preview
    return false unless decode_selection

    @blocks = SlotBlock.where(id: @revisions.keys).order(:blocked_date, :dock_number, :slot_number).to_a
    validate_current
  end

  def call
    return false unless decode_selection

    ApplicationRecord.transaction(requires_new: true) do
      return fail_operation("Sua autorização foi alterada. Entre novamente.", :forbidden) if @actor && !User.lock.find_by(id: @actor.id, active: true)&.role.in?(%w[admin operator])
      hints = SlotBlock.where(id: @revisions.keys).to_a
      return fail_operation(STALE_MESSAGE, :conflict) unless hints.size == @revisions.size

      AgendaCapacityLock.lock_positions!(hints.map(&:agenda_position))
      @blocks = SlotBlock.where(id: @revisions.keys).order(:blocked_date, :dock_number, :slot_number).lock.to_a
      return false unless validate_current

      positions = blocks.map { |block| [ block.blocked_date, block.dock_number, block.slot_number ] }
      active = Booking.where(booking_date: blocks.map(&:blocked_date).uniq, dock_number: blocks.map(&:dock_number).uniq,
        slot_number: blocks.map(&:slot_number).uniq, status: BookingAvailability::CAPACITY_STATUSES).pluck(:booking_date, :dock_number, :slot_number)
      @reserved_count = (positions & active).size
      blocks.each do |block|
        AuditEvent.record!({ entity_type: "SlotBlock", entity_id: block.id, action: "unblock", reason: block.reason,
          previous_values: block.attributes.slice("blocked_date", "dock_number", "slot_number", "reason") }, actor: @actor)
        block.destroy!
        @removed_count += 1
      end
      true
    end
  rescue ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked
    fail_operation(STALE_MESSAGE, :conflict)
  rescue ActiveRecord::ActiveRecordError
    fail_operation("Não foi possível concluir o desbloqueio. Nenhum bloqueio foi removido.", :service_unavailable)
  end

  private

  def decode_selection
    unless tokens.is_a?(Array) && tokens.size.between?(1, 80) && tokens.all? { |token| token.is_a?(String) && token.bytesize.between?(1, 2048) }
      return fail_operation("Selecione entre 1 e 80 bloqueios válidos.")
    end
    @revisions = {}
    tokens.each do |token|
      snapshot = SlotBlock.decode_unlock_token(token)
      return fail_operation(STALE_MESSAGE, :conflict) unless snapshot

      id, revision = snapshot.values_at("id", "revision")
      return fail_operation(STALE_MESSAGE, :conflict) if @revisions.key?(id) && @revisions[id] != revision

      @revisions[id] = revision
    end
    if @expected_id && @revisions.keys.map(&:to_s) != [ @expected_id.to_s ]
      return fail_operation("O identificador do bloqueio não corresponde à confirmação.")
    end
    true
  end

  def validate_current
    unless blocks.size == @revisions.size && blocks.all? { |block| block.unlock_revision == @revisions[block.id] }
      return fail_operation(STALE_MESSAGE, :conflict)
    end
    now = Time.current
    unless blocks.all? { |block| block.unblock_eligible?(now: now) }
      return fail_operation("Somente posições futuras dentro do horizonte operacional podem ser desbloqueadas.")
    end
    true
  end

  def fail_operation(message, status = :unprocessable_entity)
    @removed_count = 0
    @reserved_count = 0
    @http_status = status
    errors.add(:base, message)
    false
  end
end
