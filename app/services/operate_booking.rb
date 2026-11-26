class OperateBooking
  include ActiveModel::Model

  VERSION_MESSAGE = "Este agendamento foi atualizado por outra operação. Consulte os dados atualizados antes de continuar."
  AUDIT_FIELDS = %w[status checkin_at released_at release_remark lock_version].freeze
  attr_reader :booking, :release_remark, :lock_version, :http_status

  def initialize(booking_id:, action:, lock_version:, release_remark: nil, actor: nil)
    raise ArgumentError, "Unknown booking operation" unless %w[checkin release].include?(action)

    @booking_id = booking_id
    @action = action
    @lock_version = lock_version.to_s
    @release_remark = release_remark.to_s.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
    @http_status = :unprocessable_entity
    @actor = actor
    super()
  end

  def call
    ApplicationRecord.transaction(requires_new: true) do
      return reject(:base, "Sua autorização foi alterada. Entre novamente.", :forbidden) if @actor && !User.lock.find_by(id: @actor.id, active: true)&.role.in?(%w[admin operator])
      @booking = Booking.find(@booking_id)
      dock = @booking.dock_number
      AgendaCapacityLock.lock_dock!(dock_number: dock)
      @booking.reload(lock: true)
      return reject(:base, VERSION_MESSAGE, :conflict) unless current_version? && @booking.dock_number == dock

      now = Time.current
      return false unless validate_operation(now)

      previous = @booking.attributes.slice(*AUDIT_FIELDS)
      changes = @action == "checkin" ? { status: "em_operacao", checkin_at: now, released_at: nil } :
        { status: "liberado", released_at: now, release_remark: release_remark }
      @booking.update!(changes)
      AuditEvent.record!({ entity_type: "Booking", entity_id: @booking.id, action: @action,
        previous_values: previous, new_values: @booking.attributes.slice(*AUDIT_FIELDS) }, actor: @actor)
      true
    end
  rescue ActiveRecord::RecordNotFound
    raise
  rescue ActiveRecord::RecordNotUnique => error
    constraint = error.cause&.result&.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
    if constraint == "bookings_dock_occupation_unique"
      reject(:base, BookingCheckinPolicy::MESSAGES.fetch(:occupied), :conflict)
    else
      reject(:base, "A operação conflitou com outra atualização. Consulte o agendamento novamente.", :conflict)
    end
  rescue ActiveRecord::StaleObjectError, ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked
    reject(:base, VERSION_MESSAGE, :conflict)
  rescue ActiveRecord::ActiveRecordError
    reject(:base, "Não foi possível concluir a operação. Nenhuma alteração foi confirmada. Tente novamente.", :service_unavailable)
  end

  private

  def current_version?
    lock_version.match?(/\A[0-9]{1,10}\z/) && lock_version.to_i == @booking.lock_version
  end

  def validate_operation(now)
    if @action == "checkin"
      reason = BookingCheckinPolicy.reason(@booking, now: now)
      return true unless reason

      reject(:base, BookingCheckinPolicy::MESSAGES.fetch(reason), %i[status occupied].include?(reason) ? :conflict : :unprocessable_entity)
    elsif @booking.status != "em_operacao"
      reject(:base, BookingCheckinPolicy::MESSAGES.fetch(:status), :conflict)
    elsif !release_remark.length.between?(3, 500)
      reject(:release_remark, "Informe uma observação de liberação com 3 a 500 caracteres.")
    elsif @booking.checkin_at.nil? || now < @booking.checkin_at
      reject(:base, "O horário de liberação não pode ser anterior ao check-in.")
    else
      true
    end
  end

  def reject(field, message, status = :unprocessable_entity)
    @http_status = status
    errors.add(field, message)
    false
  end
end
