require "test_helper"
require_relative "../support/user_data"

class UsersConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests=false
  include UserData
  setup { @ids=[] }
  teardown do
    with_audit_cleanup { AuditEvent.where(entity_type: "User", entity_id: @ids).delete_all }
    User.where(id: @ids).delete_all
  end

  test "concurrent deactivations cannot remove both active admins" do
    protect_admins("deactivate", "deactivate")
  end

  test "concurrent role changes cannot demote both active admins" do
    protect_admins("update", "update")
  end

  test "concurrent deactivation and role change leave an active admin" do
    protect_admins("deactivate", "update")
  end

  test "concurrent creation with duplicate email only commits one account and audit" do
    email="race-#{SecureRandom.hex(6)}@example.test"
    actor=-> do
      operation=ManageUser.new(action: "create", attributes: user_attributes(email: email))
      success=operation.call
      @ids<<operation.user.id if success
      success
    end
    assert_equal [ true, false ], contend(actor, actor)
    assert_equal 1, User.where(email: email).count
    assert_equal 1, AuditEvent.where(entity_type: "User", entity_id: @ids).count
  end

  test "simultaneous bootstrap attempts initialize once without replacing the winner" do
    actor=-> do
      operation=ManageUser.new(action: "bootstrap", attributes: user_attributes)
      success=operation.call
      @ids<<operation.user.id if operation.user
      [ success, operation.already_initialized==true ]
    end
    results=contend(actor, actor)
    assert_equal [ [ true, false ], [ true, true ] ], results
    assert_equal 1, User.where(id: @ids, role: "admin", active: true).count
    assert_equal 1, AuditEvent.where(entity_type: "User", entity_id: @ids).count
  end

  private

  def protect_admins(first_action, second_action)
    users=2.times.map { user=create_user(role: "admin");@ids<<user.id;user }
    actors=users.each_with_index.map do |user, index|
      -> { ManageUser.new(action: [ first_action, second_action ][index], user_id: user.id, lock_version: 0, attributes: { role: "viewer" }, reason: "Mudança de equipe").call }
    end
    assert_equal [ true, false ], contend(*actors)
    assert_equal 1, User.where(id: @ids, role: "admin", active: true).count
    assert_equal 1, AuditEvent.where(entity_type: "User", entity_id: @ids).count
  end

  def contend(first, second)
    ready, commit, results, waiting=Array.new(4) { Queue.new }
    one=Thread.new do
      ApplicationRecord.connection_pool.with_connection do |connection|
        connection.transaction do
          outcome=first.call
          ready<<connection.raw_connection.backend_pid
          raise "commit timeout" unless commit.pop(timeout: 10)
          results<<outcome
        end
      end
    rescue StandardError=>error
      ready<<error
    end
    first_pid=ready.pop(timeout: 10)
    assert_kind_of Integer, first_pid
    two=Thread.new do
      ApplicationRecord.connection_pool.with_connection do |connection|
        waiting<<connection.raw_connection.backend_pid
        results<<second.call
      end
    rescue StandardError=>error
      results<<error
    end
    second_pid=waiting.pop(timeout: 10)
    assert_not_equal first_pid, second_pid
    deadline=Process.clock_gettime(Process::CLOCK_MONOTONIC)+4
    loop do
      bind=ActiveRecord::Relation::QueryAttribute.new("pid", second_pid, ActiveRecord::Type::Integer.new)
      blocked=ApplicationRecord.connection.exec_query("SELECT cardinality(pg_blocking_pids($1)) > 0 AS blocked", "Observe contention", [ bind ]).first.fetch("blocked")
      break if blocked
      flunk "No actual PostgreSQL contention observed" if Process.clock_gettime(Process::CLOCK_MONOTONIC)>=deadline
      sleep 0.01
    end
    commit<<true
    assert one.join(10)
    assert two.join(10)
    Array.new(2) { results.pop(timeout: 1) }
  ensure
    commit<<true
    [ one, two ].compact.each { |thread| thread.join(10)||thread.kill.join }
  end
end
