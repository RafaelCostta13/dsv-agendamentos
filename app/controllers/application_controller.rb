class ApplicationController < ActionController::Base
  AUTH_COOKIE = :dsv_admin_session
  helper_method :current_user, :authenticated?, :allowed?
  rescue_from ActiveRecord::ActiveRecordError do
    response.headers["Cache-Control"] = "no-store"
    render plain: "Serviço temporariamente indisponível. Tente novamente.", status: :service_unavailable
  end

  private

  def authenticate_user!
    token = cookies.encrypted[AUTH_COOKIE]
    auth_session = Session.includes(:user).find_by_token(token)
    if auth_session&.valid_at?
      Current.session = auth_session
      Current.user = auth_session.user
      auth_session.update_columns(last_seen_at: Time.current, updated_at: Time.current) unless polling_request?
      return true
    end

    auth_session&.revoke!
    delete_auth_cookie
    if polling_request?
      response.headers["X-Login-URL"] = login_path
      head :unauthorized
    else
      store_return_location
      redirect_to login_path, alert: token.present? ? "Sua sessão expirou. Entre novamente para continuar." : "Entre no sistema para continuar."
    end
    false
  end

  def current_user
    Current.user
  end

  def authenticated?
    current_user.present?
  end

  def allowed?(permission)
    AuthorizationPolicy.allowed?(current_user, permission)
  end

  def polling_request?
    controller_path == "admin/dashboard" && action_name == "refresh"
  end

  def establish_authentication(user)
    reset_session
    auth_session, token = Session.issue!(user: user, user_agent: request.user_agent)
    cookies.encrypted[AUTH_COOKIE] = { value: token, httponly: true, secure: Rails.env.production?, same_site: :lax, path: "/" }
    Current.user = user
    Current.session = auth_session
  end

  def end_authentication
    Current.session&.revoke!
    delete_auth_cookie
    reset_session
    Current.reset
  end

  def delete_auth_cookie
    cookies.delete(AUTH_COOKIE, path: "/", secure: Rails.env.production?, same_site: :lax)
  end

  def store_return_location
    return unless request.get? && request.path.start_with?("/admin") && request.fullpath.bytesize <= 1000
    session[:return_to] = request.fullpath
  end

  def safe_return_location
    location = session.delete(:return_to).to_s
    location.match?(/\A\/admin(?:\/|\?|\z)/) && !location.match?(/[\\\r\n]/) ? location : admin_root_path
  end
end
