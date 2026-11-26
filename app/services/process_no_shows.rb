class ProcessNoShows
  REASON = "Não comparecimento até o horário limite de check-in."
  AUDIT_FIELDS = %w[status booking_date dock_number slot_number change_reason lock_version].freeze

  def call
    limit = AgendaDefinition.no_show_date_limit
    scope = Booking.where(status: "agendado").where(booking_date: ..limit)
    counts = { eligible: 0, processed: 0, ignored: 0, failed: 0, inconsistent: 0 }
    scope.where.not(checkin_at: nil).find_each(batch_size: 100) do |booking|
      counts[:inconsistent] += 1
      Rails.logger.warn("no_show inconsistent booking_id=#{booking.id}")
    end
    scope.where(checkin_at: nil).find_each(batch_size: 100) do |booking|
      counts[:eligible] += 1
      counts[process_booking(booking.id)] += 1
    rescue ActiveRecord::ActiveRecordError => error
      counts[:failed] += 1
      Rails.logger.error("no_show failed booking_id=#{booking.id} error_class=#{error.class.name}")
    end
    counts
  end

  def process_booking(id)
    ApplicationRecord.transaction(requires_new: true) do
      booking = Booking.find_by(id: id)
      return :ignored unless booking

      position, version, request = booking.agenda_position, booking.lock_version, booking.request_id
      AgendaCapacityLock.lock_request!(request)
      AgendaCapacityLock.lock_dock!(dock_number: position.fetch(:dock_number))
      AgendaCapacityLock.lock_positions!([ position ])
      booking.reload(lock: true)
      unless booking.agenda_position == position && booking.lock_version == version && booking.request_id == request
        return :ignored
      end
      return :ignored unless booking.no_show_due?

      previous = booking.attributes.slice(*AUDIT_FIELDS)
      booking.update!(status: "reagendamento", change_reason: REASON)
      AuditEvent.record!({ entity_type: "Booking", entity_id: booking.id, action: "no_show", reason: REASON,
        previous_values: previous, new_values: booking.attributes.slice(*AUDIT_FIELDS) }, origin: "system")
      :processed
    end
  end
end
