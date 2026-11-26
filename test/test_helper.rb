ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
ActiveModel::SecurePassword.min_cost = true
require_relative "support/audit_cleanup"
require_relative "support/authentication_helpers"

module ActiveSupport
  class TestCase
    include AuditCleanup
    include AuthenticationHelpers
    fixtures :all
  end
end
