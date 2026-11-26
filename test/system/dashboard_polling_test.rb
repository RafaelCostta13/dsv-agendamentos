require "test_helper"
require "open3"
require "timeout"
require "puma"

class DashboardPollingTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "the real Rails dashboard loads its nonce-authorized asset and polls the selected date" do
    user = create_user(must_change_password: false)
    login = ActionDispatch::Integration::Session.new(Rails.application)
    login.post "/login", params: { login: { email: user.email, password: "Frase de teste com espaços!" } }
    assert_equal 303, login.response.status
    cookie = Array(login.response.headers.fetch("Set-Cookie")).find { |value| value.start_with?("dsv_admin_session=") }.split(";", 2).first
    requests = Queue.new
    app = ->(env) do
      env["HTTP_COOKIE"] = cookie if env["PATH_INFO"].start_with?("/admin")
      requests << [ env["PATH_INFO"], env["QUERY_STRING"] ]
      Rails.application.call(env)
    end
    server = Puma::Server.new(app, nil, min_threads: 1, max_threads: 2)
    server.add_tcp_listener("127.0.0.1", 0)
    port = server.binder.ios.first.addr[1]
    server.run
    browser = ENV.fetch("CHROMIUM_BIN", "/usr/bin/chromium")
    output, status = Timeout.timeout(30) do
      Open3.capture2e(browser, "--headless", "--no-sandbox", "--disable-dev-shm-usage", "--disable-background-networking", "--virtual-time-budget=6500", "--dump-dom", "http://127.0.0.1:#{port}/admin?date=2026-11-27")
    end
    assert status.success?
    page = Nokogiri::HTML(output)
    assert_equal 80, page.css(".admin-matrix tbody td").size
    assert_equal "active", page.at_css("[data-polling-status]").parent["data-state"]
    observed = []
    observed << requests.pop until requests.empty?
    assert observed.any? { |path, _| path.include?("dashboard_polling") }, observed.inspect
    assert observed.any? { |path, query| path == "/admin/dashboard/refresh" && query == "date=2026-11-27" }, observed.inspect
    assert_equal "2026-11-27", page.at_css("#dashboard-data")["data-date"]
    refute_match(/violates.*Content Security Policy/i, output)
  ensure
    server&.stop(true)
    if user
      Session.where(user_id: user.id).delete_all
      with_audit_cleanup { AuditEvent.where(entity_type: "User", entity_id: user.id).delete_all }
      User.where(id: user.id).delete_all
      LoginAttempt.where(key_digest: [ OpenSSL::Digest::SHA256.hexdigest("email:#{user.email}"), OpenSSL::Digest::SHA256.hexdigest("ip:127.0.0.1") ]).delete_all
    end
  end

  test "dashboard polling lifecycle and recovery execute in a real headless browser" do
    browser=ENV.fetch("CHROMIUM_BIN", "/usr/bin/chromium")
    assert File.executable?(browser), "Install Chromium in the test environment or set CHROMIUM_BIN"
    uri="file://#{Rails.root.join('test/javascript/dashboard_polling_test.html')}"
    output, status=Timeout.timeout(30) do
      Open3.capture2e(browser, "--headless", "--no-sandbox", "--disable-dev-shm-usage", "--disable-background-networking", "--allow-file-access-from-files", "--virtual-time-budget=10000", "--dump-dom", uri)
    end
    assert status.success?, output.lines.last(5).join
    node=Nokogiri::HTML(output).at_css("#results")
    assert node, output.lines.last(5).join
    result=JSON.parse(node.text)
    assert_nil result["error"], result.inspect
    assert_equal 8, result["passed"], result.inspect
  end
end
