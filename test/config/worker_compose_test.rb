require "test_helper"
require "yaml"

class WorkerComposeTest < ActiveSupport::TestCase
  test "worker shares Rails image and database configuration without publishing web ports" do
    config = YAML.safe_load(File.read(Rails.root.join("compose.yaml")), aliases: true)
    web, worker = config.fetch("services").values_at("web", "worker")
    assert_equal web.fetch("image"), worker.fetch("image")
    assert_equal web.fetch("environment"), worker.fetch("environment")
    assert_equal [ "bundle", "exec", "ruby", "bin/no-show-worker" ], worker.fetch("command")
    assert_nil worker["ports"]
    assert_equal 1, web.fetch("ports").size
    assert_equal "unless-stopped", worker.fetch("restart")
    assert_equal "service_healthy", worker.dig("depends_on", "db", "condition")
    assert_includes File.read(Rails.root.join("Dockerfile")), "USER rails:rails"
  end
end
