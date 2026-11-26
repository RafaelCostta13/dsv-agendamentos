class AuthenticatedOperation
  class Denied < StandardError; end

  def self.call(user:, session:, permission: nil, restricted: false)
    ApplicationRecord.transaction(requires_new: true) do
      AgendaCapacityLock.lock_user_management!
      actor = User.lock.find_by(id: user.id)
      credential = Session.lock.find_by(id: session.id, user_id: user.id)
      credential.user = actor if credential
      unless credential&.valid_at? && (restricted || !actor.must_change_password?) && (!permission || AuthorizationPolicy.allowed?(actor, permission))
        raise Denied
      end
      Current.set(user: actor, session: credential) { yield }
    end
  end
end
