module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :restrict_environment
    before_action :disable_caching
    before_action :authenticate_user!
    before_action :require_completed_password_change
    before_action :authorize_request
    around_action :guard_sensitive_operation
    rescue_from AuthenticatedOperation::Denied, with: :authorization_changed
    rescue_from ActiveRecord::ActiveRecordError, with: :database_unavailable
    rescue_from ActiveRecord::RecordNotFound, with: :booking_not_found

    private

    def guard_sensitive_operation
      if request.get? && action_name != "export"
        yield
      else
        AuthenticatedOperation.call(user: current_user, session: Current.session,
          permission: AuthorizationPolicy.permission_for(controller_path, action_name)) { yield }
      end
    end

    def authorization_changed
      render "admin/shared/forbidden", status: :forbidden
    end

    def restrict_environment
      head :not_found unless Rails.env.development? || Rails.env.test? || ENV["ADMIN_ACCESS_ENABLED"] == "true"
    end

    def disable_caching
      response.headers["Cache-Control"] = "no-store"
      response.headers["Pragma"] = "no-cache"
    end

    def database_unavailable
      unless current_user
        return render plain: "Serviço temporariamente indisponível. Tente novamente.", status: :service_unavailable
      end
      render_query_error("Consulta indisponível", "Não foi possível consultar os agendamentos. Tente novamente.", :service_unavailable)
    end

    def booking_not_found
      render_query_error("Agendamento não encontrado", "A reserva solicitada não foi encontrada.", :not_found)
    end

    def render_query_error(title, message, status)
      filters.valid?
      render "admin/shared/error", locals: { title: title, message: message }, status: status
    end

    def require_completed_password_change
      return unless current_user&.must_change_password?
      if polling_request?
        response.headers["X-Login-URL"] = edit_password_path
        head :unauthorized
      else
        redirect_to edit_password_path, alert: "Por segurança, altere sua senha antes de continuar."
      end
    end

    def authorize_request
      permission = AuthorizationPolicy.permission_for(controller_path, action_name)
      return if allowed?(permission)
      render "admin/shared/forbidden", status: :forbidden
    end

    def filters
      @filters ||= BookingFilters.new(params.permit(:date, :dock_number, :operation, :status, :start_date, :end_date).to_h)
    end

    def selected_date
      filters.parsed_date || @booking&.booking_date || Date.current
    end
    def admin_context
      filters.query_parameters.merge(page: params[:page].to_s.match?(/\A[1-9][0-9]{0,8}\z/) ? params[:page] : nil).compact
    end
    helper_method :selected_date, :admin_context
  end
end
