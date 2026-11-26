module Admin
  class DashboardController < BaseController
    POLL_INTERVAL_MS = 5_000
    POLL_TIMEOUT_MS = 10_000
    MAX_RETRY_MS = 30_000

    before_action :authorize_dashboard_script, only: :index

    def index
      filters.valid?
      load_dashboard
    end

    def refresh
      unless filters.valid? && filters.parsed_date
        return render plain: "Data inválida.", status: :unprocessable_entity
      end

      load_dashboard
      render partial: "content"
    end

    private

    def load_dashboard
      @rendered_at = Time.current
      @dashboard = Dashboard.new(date: selected_date, now: @rendered_at)
    end

    def authorize_dashboard_script
      @dashboard_nonce = SecureRandom.base64(32)
      request.content_security_policy = request.content_security_policy.clone
      request.content_security_policy.script_src "'nonce-#{@dashboard_nonce}'"
    end
  end
end
