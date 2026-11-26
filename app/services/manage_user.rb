class ManageUser
  include ActiveModel::Model
  FIELDS = %w[name email role active must_change_password password_changed_at deactivated_at].freeze
  VERSION_MESSAGE = "O usuário foi atualizado por outra operação. Consulte os dados atualizados antes de continuar."
  attr_reader :user, :http_status, :already_initialized

  def initialize(action:, attributes: {}, user_id: nil, lock_version: nil, reason: nil, actor: nil)
    raise ArgumentError, "Unknown user operation" unless %w[create bootstrap update activate deactivate password_reset].include?(action)
    @action, @attributes, @user_id, @version = action, attributes.symbolize_keys, user_id, lock_version.to_s
    @reason = reason.to_s.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")
    @actor = actor
    @http_status = :unprocessable_entity
    super()
  end

  def call
    ApplicationRecord.transaction(requires_new: true) do
      AgendaCapacityLock.lock_user_management!
      if @action == "bootstrap" && User.where(role: "admin").exists?
        @already_initialized = true
        return true
      end
      if %w[create bootstrap].include?(@action)
        @user = User.new(@attributes.slice(:name, :email, :role, :active, :password, :password_confirmation))
        @user.role, @user.active = "admin", true if @action == "bootstrap"
        @user.must_change_password = true
        @user.password_changed_at = Time.current
        @user.deactivated_at = @user.active == false ? Time.current : nil
        return false unless valid_user?
        @user.save!
        audit("user_created", nil, @user.attributes.slice(*FIELDS), reason: @action == "bootstrap" ? "Inicialização interna do administrador." : nil)
        return true
      end
      @user = User.lock.find(@user_id)
      unless @version.match?(/\A[0-9]{1,10}\z/) && @version.to_i == @user.lock_version
        return reject(VERSION_MESSAGE, :conflict)
      end
      previous = @user.attributes.slice(*FIELDS)
      case @action
      when "update" then @user.assign_attributes(@attributes.slice(:name, :email, :role))
      when "activate" then @user.assign_attributes(active: true, deactivated_at: nil)
      when "deactivate"
        return true unless @user.active
        return false unless valid_reason?
        @user.assign_attributes(active: false, deactivated_at: Time.current)
      when "password_reset"
        return false unless valid_reason?
        @user.assign_attributes(@attributes.slice(:password, :password_confirmation))
        @user.password_changed_at = Time.current
        @user.must_change_password = true
      end
      return false unless valid_user?
      if previous["role"] == "admin" && previous["active"] && !(@user.role == "admin" && @user.active) && User.where(role: "admin", active: true).where.not(id: @user.id).none?
        return reject("O sistema precisa possuir pelo menos um administrador ativo.", :conflict)
      end
      return true unless @user.changed?
      @user.save!(context: @action == "password_reset" ? :password_reset : nil)
      if @action == "password_reset" || @action == "deactivate" || (@action == "update" && (previous["role"] != @user.role || previous["email"] != @user.email))
        Session.where(user_id: @user.id, revoked_at: nil).update_all(revoked_at: Time.current, updated_at: Time.current)
      end
      record_changes(previous)
      true
    end
  rescue ActiveRecord::RecordInvalid => failure
    if failure.record.equal?(user) && user.errors.any?
      user.errors.each { |error| errors.add(:base, error.message) }
      false
    else
      Rails.logger.error("user_management audit_failed error_class=#{failure.class.name}")
      reject("Não foi possível concluir a operação. Nenhuma alteração foi confirmada.", :service_unavailable)
    end
  rescue ActiveRecord::RecordNotUnique
    reject("Este endereço de e-mail já está cadastrado.", :conflict)
  rescue ActiveRecord::StaleObjectError, ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked
    reject(VERSION_MESSAGE, :conflict)
  rescue ActiveRecord::RecordNotFound
    raise
  rescue ActiveRecord::ActiveRecordError => error
    Rails.logger.error("user_management failed action=#{@action} error_class=#{error.class.name}")
    reject("Não foi possível concluir a operação. Nenhuma alteração foi confirmada.", :service_unavailable)
  end

  private

  def valid_user?
    return true if @user.valid?(@action == "password_reset" ? :password_reset : nil)
    @user.errors.each { |error| errors.add(:base, error.message) }
    false
  end

  def valid_reason?
    return true if @reason.length <= 500 && @reason.gsub(/[[:space:]]/, "").length >= 3
    reject("Informe um motivo com 3 a 500 caracteres úteis.")
  end

  def reject(message, status = :unprocessable_entity)
    @http_status = status
    errors.add(:base, message)
    false
  end

  def audit(action, before, after, reason: nil)
    origin = @action == "bootstrap" ? "bootstrap" : (@actor ? "authenticated_user" : "unknown")
    AuditEvent.record!({ entity_type: "User", entity_id: @user.id, action: action, previous_values: before, new_values: after, reason: reason }, actor: @actor, origin: origin)
  end

  def record_changes(previous)
    current = @user.attributes.slice(*FIELDS)
    case @action
    when "update"
      keys = %w[name email].select { |key| previous[key] != current[key] }
      audit("user_updated", previous.slice(*keys), current.slice(*keys)) if keys.any?
      audit("user_role_changed", previous.slice("role"), current.slice("role")) if previous["role"] != current["role"]
    when "activate", "deactivate"
      audit("user_#{@action == 'activate' ? 'activated' : 'deactivated'}", previous.slice("active", "deactivated_at"), current.slice("active", "deactivated_at"), reason: @reason.presence)
    when "password_reset"
      audit("user_password_reset", previous.slice("must_change_password", "password_changed_at"), current.slice("must_change_password", "password_changed_at"), reason: @reason)
    end
  end
end
