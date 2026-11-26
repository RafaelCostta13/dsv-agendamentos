class User < ApplicationRecord
  ROLES = { "admin" => "Administrador", "operator" => "Operador", "viewer" => "Consulta" }.freeze
  ROLE_DESCRIPTIONS = {
    "admin" => "Acesso completo ao sistema e gerenciamento das configurações e dos usuários.",
    "operator" => "Gerenciamento operacional dos agendamentos, entradas, liberações, cancelamentos, reagendamentos e bloqueios.",
    "viewer" => "Consulta de informações operacionais, histórico e exportação de agendamentos."
  }.freeze
  has_secure_password validations: false, reset_token: false
  has_many :sessions, dependent: :restrict_with_exception
  normalizes :name, with: ->(value) { value.to_s.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "") }
  normalizes :email, with: ->(value) { value.to_s.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "").downcase }

  validates :name, length: { maximum: 100, message: "O nome deve ter no máximo 100 caracteres." }
  validate :valid_name
  validates :email, presence: { message: "Informe um endereço de e-mail válido." }, length: { maximum: 254, message: "O e-mail deve ter no máximo 254 caracteres." },
    format: { with: URI::MailTo::EMAIL_REGEXP, message: "Informe um endereço de e-mail válido." },
    uniqueness: { case_sensitive: false, message: "Este endereço de e-mail já está cadastrado." }
  validates :role, inclusion: { in: ROLES.keys, message: "Selecione um perfil de acesso válido." }
  validates :password_digest, presence: { message: "Informe uma senha inicial válida." }
  validates :lock_version, numericality: { only_integer: true, greater_than_or_equal_to: 0, message: "A versão do registro é inválida." }
  validates :must_change_password, inclusion: { in: [ true, false ], message: "A indicação de troca de senha é inválida." }
  validate :consistent_state
  validate :password_policy

  def password=(value)
    @password = value
    return unless value.is_a?(String) && value.bytesize <= 72 && !value.include?("\0")
    super
  end

  private

  def valid_name
    if name.to_s.gsub(/[[:space:]]/, "").length < 2 || name.to_s.match?(/[[:cntrl:]]/)
      errors.add(:name, "Informe um nome válido.")
    end
  end

  def consistent_state
    unless [ true, false, 1, 0, "1", "0", "true", "false" ].include?(active_before_type_cast)
      errors.add(:active, "Selecione um estado válido.")
    end
    if active.nil? || (active && deactivated_at.present?) || (active == false && deactivated_at.nil?)
      errors.add(:active, "O estado e a data de desativação são incompatíveis.")
    end
  end

  def password_policy
    return unless new_record? || validation_context == :password_reset || !password.nil?
    if !password.is_a?(String) || password.length < 12
      errors.add(:password, "A senha deve possuir pelo menos 12 caracteres.")
    elsif password.bytesize > 72 || password.include?("\0")
      errors.add(:password, "A senha ultrapassa o tamanho permitido ou contém caracteres inválidos.")
    end
    unless password_confirmation.is_a?(String) && password_confirmation == password
      errors.add(:password_confirmation, "As senhas informadas não são iguais.")
    end
  end
end
