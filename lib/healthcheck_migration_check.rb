class HealthcheckMigrationCheck
  HEALTHCHECK_PATHS = %w[/up /ready].freeze

  def initialize(app)
    @app = app
    @migration_check = ActiveRecord::Migration::CheckPending.new(app)
  end

  def call(env)
    if HEALTHCHECK_PATHS.include?(env["PATH_INFO"])
      @app.call(env)
    else
      @migration_check.call(env)
    end
  end
end
