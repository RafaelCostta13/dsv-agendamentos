require "pg"

class ReadinessController < ApplicationController
  # Do not expose the Rails development exception page for database failures.
  rescue_from ActiveRecord::ActiveRecordError, PG::Error, with: :unavailable

  def show
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.select_value("SELECT 1")
    end
    response.headers["Cache-Control"] = "no-store"
    render plain: "ok", status: :ok
  end

  private

  def unavailable
    response.headers["Cache-Control"] = "no-store"
    render plain: "unavailable", status: :service_unavailable
  end
end
