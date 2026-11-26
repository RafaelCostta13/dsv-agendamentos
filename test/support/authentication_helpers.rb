require_relative "user_data"

module AuthenticationHelpers
  include UserData

  def sign_in_as(role: "admin", must_change_password: false)
    password = "Senha administrativa de teste!"
    user = create_user(name: "Administrador dos testes", role: role, must_change_password: must_change_password,
      password: password, password_confirmation: password, password_changed_at: Time.current)
    post login_path, params: { login: { email: user.email, password: password } }
    assert_response :see_other
    user
  end
end
