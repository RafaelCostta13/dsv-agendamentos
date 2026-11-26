class SessionsController < ApplicationController
  layout "authentication"
  before_action :redirect_authenticated, only: :new
  before_action :disable_caching
  before_action :authorize_authentication_script, only: %i[new create]
  rescue_from AuthenticatedOperation::Denied do
    delete_auth_cookie
    redirect_to login_path, status: :see_other
  end

  def new
    @email = ""
  end

  def create
    values = params.require(:login).permit(:email, :password)
    @email = values[:email].to_s
    authentication = AuthenticateUser.new(email: @email, password: values[:password], ip: request.remote_ip)
    success = authentication.call do |user|
      establish_authentication(user)
      AuditEvent.record!({ entity_type: "User", entity_id: user.id, action: "login_success" }, actor: user)
    end
    if success
      redirect_to authentication.user.must_change_password? ? edit_password_path : safe_return_location, status: :see_other
    elsif authentication.rate_limited?
      response.headers["Retry-After"] = authentication.retry_after.to_s
      Rails.logger.warn("authentication rate_limited ip_digest=#{OpenSSL::Digest::SHA256.hexdigest(request.remote_ip.to_s)[0, 12]}")
      flash.now[:alert] = "Muitas tentativas de acesso. Aguarde alguns minutos e tente novamente."
      render :new, status: :too_many_requests
    else
      flash.now[:alert] = "E-mail ou senha inválidos."
      Rails.logger.warn("authentication failed ip_digest=#{OpenSSL::Digest::SHA256.hexdigest(request.remote_ip.to_s)[0, 12]}")
      render :new, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing
    @email = ""
    flash.now[:alert] = "E-mail ou senha inválidos."
    render :new, status: :unprocessable_entity
  end

  def destroy
    return unless authenticate_user!
    AuthenticatedOperation.call(user: current_user, session: Current.session, restricted: true) do
      user = current_user
      AuditEvent.record!({ entity_type: "User", entity_id: user.id, action: "logout" }, actor: user)
      end_authentication
    end
    redirect_to login_path, status: :see_other, notice: "Você saiu do sistema."
  end

  private

  def redirect_authenticated
    token = cookies.encrypted[AUTH_COOKIE]
    auth_session = Session.includes(:user).find_by_token(token)
    return unless auth_session&.valid_at?
    Current.session, Current.user = auth_session, auth_session.user
    redirect_to auth_session.user.must_change_password? ? edit_password_path : admin_root_path
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
