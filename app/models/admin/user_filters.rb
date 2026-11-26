module Admin
  class UserFilters
    include ActiveModel::Model
    attr_accessor :q, :role, :state
    validates :q, length: { maximum: 100, message: "A pesquisa deve ter no máximo 100 caracteres." }
    validates :role, inclusion: { in: User::ROLES.keys, message: "Selecione um perfil válido." }, allow_blank: true
    validates :state, inclusion: { in: %w[active inactive], message: "Selecione um estado válido." }, allow_blank: true

    def scope
      return User.none unless valid?
      records = User.all
      if q.present?
        pattern = "%#{User.sanitize_sql_like(q)}%"
        records = records.where("name ILIKE :query OR email ILIKE :query", query: pattern)
      end
      records = records.where(role: role) if role.present?
      records = records.where(active: state == "active") if state.present?
      records
    end

    def query_parameters
      { q: q, role: role, state: state }.select { |_, value| value.present? }
    end
  end
end
