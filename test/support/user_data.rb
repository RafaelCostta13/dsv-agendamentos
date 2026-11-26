module UserData
  private

  def user_attributes(**values)
    { name: "Usuário de teste", email: "user-#{SecureRandom.hex(6)}@example.test", role: "operator", active: true,
      password: "Frase de teste com espaços!", password_confirmation: "Frase de teste com espaços!" }.merge(values)
  end

  def create_user(**values)
    user=User.create!(user_attributes(**values))
    user
  end
end
