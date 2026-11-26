require "digest"

class SlotBlock < ApplicationRecord
  validates :blocked_date, presence: true
  validates :dock_number, numericality: { only_integer: true, in: AgendaDefinition::DOCK_NUMBERS }
  validates :slot_number, numericality: { only_integer: true, in: AgendaDefinition::SLOT_NUMBERS }
  validates :reason, length: { maximum: 250 }, allow_nil: true
  def agenda_position
    { date: blocked_date, dock_number: dock_number, slot_number: slot_number }
  end

  def unblock_eligible?(now: Time.current)
    AgendaDefinition.future_slot?(blocked_date, slot_number, now: now)
  end

  def unlock_revision
    Digest::SHA256.hexdigest([ id, blocked_date.iso8601, dock_number, slot_number, reason,
      created_at.utc.iso8601(6), updated_at.utc.iso8601(6) ].to_json)
  end

  def unlock_token
    Rails.application.message_verifier("slot-block-unlock").generate({ "id" => id, "revision" => unlock_revision },
      purpose: "slot-block-unlock-v1", expires_in: 2.hours)
  end

  def self.decode_unlock_token(token)
    value = Rails.application.message_verifier("slot-block-unlock").verified(token, purpose: "slot-block-unlock-v1")
    return unless value.is_a?(Hash) && value["id"].is_a?(Integer) && value["id"].positive? && value["revision"].to_s.match?(/\A[0-9a-f]{64}\z/)

    value
  end
end
