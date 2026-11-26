class AuditEvent < ApplicationRecord
  ENTITY_TYPES = %w[Booking SlotBlock User].freeze

  validates :entity_type, inclusion: { in: ENTITY_TYPES }
  validates :entity_id, :action, presence: true
  validates :entity_type, :action, length: { maximum: 50 }
  belongs_to :actor_user, class_name: "User", optional: true
  validates :origin, inclusion: { in: %w[public_form authenticated_user system bootstrap unknown] }, allow_nil: true
  validates :actor_role, inclusion: { in: User::ROLES.keys }, allow_nil: true

  def self.record!(attributes, actor: nil, origin: nil)
    source = origin || (actor ? "authenticated_user" : "unknown")
    create!(**attributes.merge(actor_user: actor, actor_name: actor&.name, actor_role: actor&.role, origin: source))
  end
end
