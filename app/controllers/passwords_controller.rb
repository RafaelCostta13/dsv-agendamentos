class PasswordsController < ApplicationController
  layout "authentication"
  before_action :disable_caching
  before_action :authenticate_user!
  before_action :authorize_authentication_script, only: :edit
  around_action :guard_password_change, only: :update
  rescue_from AuthenticatedOperation::Denied do
    redirect_to login_path, status: :see_other, alert: "Sua sessão expirou. Entre novamente para continuar."
  end

  def edit
    @change = ChangeOwnPassword.new(user: current_user, current_password: nil, password: nil, password_confirmation: nil)
  end

  def update
    values = params.require(:password_change).permit(:current_password, :password, :password_confirmation)
    @change = ChangeOwnPassword.new(user: current_user, **values.to_h.symbolize_keys.reverse_merge(current_password: nil, password: nil, password_confirmation: nil))
    if @change.call
      delete_auth_cookie
      reset_session
      Current.reset
      redirect_to login_path, status: :see_other, notice: "Senha alterada. Entre novamente com a nova senha."
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing
    @change = ChangeOwnPassword.new(user: current_user, current_password: nil, password: nil, password_confirmation: nil)
    @change.errors.add(:base, "Preencha todos os campos de senha.")
    render :edit, status: :unprocessable_entity
  end

  private

  def guard_password_change
    AuthenticatedOperation.call(user: current_user, session: Current.session, restricted: true) { yield }
  end

  def disable_caching
    response.headers["Cache-Control"] = "no-store"
  end

  def authorize_authentication_script
    @authentication_nonce = SecureRandom.base64(32)
    request.content_security_policy = request.content_security_policy.clone
    request.content_security_policy.script_src "'nonce-#{@authentication_nonce}'"
  end
end
