class ChangeOwnPassword
  include ActiveModel::Model
  attr_reader :user

  def initialize(user:, current_password:, password:, password_confirmation:)
    @user_id = user.id
    @current_password = current_password
    @password = password
    @password_confirmation = password_confirmation
    super()
  end

  def call
    ApplicationRecord.transaction(requires_new: true) do
      AgendaCapacityLock.lock_user_management!
      @user = User.lock.find(@user_id)
      return reject("Informe senhas válidas com até 72 bytes.") unless [ @current_password, @password ].all? { |value| value.is_a?(String) && value.bytesize.between?(1, 72) && !value.include?("\0") }
      return reject("A senha atual não confere.") unless @user.active? && @user.authenticate(@current_password)
      return reject("A nova senha deve ser diferente da senha atual.") if @user.authenticate(@password.to_s)

      previous = @user.attributes.slice("must_change_password", "password_changed_at")
      @user.assign_attributes(password: @password, password_confirmation: @password_confirmation,
        must_change_password: false, password_changed_at: Time.current)
      unless @user.valid?(:password_reset)
        @user.errors.each { |error| errors.add(:base, error.message) }
        raise ActiveRecord::Rollback
      end
      @user.save!(context: :password_reset)
      Session.where(user_id: @user.id, revoked_at: nil).update_all(revoked_at: Time.current, updated_at: Time.current)
      AuditEvent.record!({ entity_type: "User", entity_id: @user.id, action: "password_changed",
        previous_values: previous, new_values: @user.attributes.slice("must_change_password", "password_changed_at") }, actor: @user)
      true
    end
  rescue ActiveRecord::ActiveRecordError => error
    Rails.logger.error("own_password_change failed error_class=#{error.class.name}")
    reject("Não foi possível alterar a senha. Tente novamente.")
  end

  private

  def reject(message)
    errors.add(:base, message)
    false
  end
end
