require "test_helper"
require_relative "../support/user_data"

class UserTest < ActiveSupport::TestCase
  include UserData

  test "native production bcrypt cost and SQL logs protect the password and digest" do
    previous = ActiveModel::SecurePassword.min_cost
    ActiveModel::SecurePassword.min_cost = false
    user = User.new(user_attributes)
    assert_equal 12, BCrypt::Password.new(user.password_digest).cost
    assert user.authenticate(user.password)
    output = StringIO.new
    logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = ActiveSupport::Logger.new(output)
    user.save!
    assert_not_includes output.string, user.password
    assert_not_includes output.string, user.password_digest
    assert_includes output.string, "[FILTERED]"
  ensure
    ActiveModel::SecurePassword.min_cost = previous
    ActiveRecord::Base.logger = logger if logger
  end

  test "normalization secure password verification and confirmation preserve exact password spaces" do
    values=user_attributes(name: "  João da Silva  ", email: "  JOAO@EXAMPLE.TEST  ", password: "  uma frase longa!  ", password_confirmation: "  uma frase longa!  ")
    user=User.create!(values)
    assert_equal "João da Silva", user.name
    assert_equal "joao@example.test", user.email
    assert user.authenticate(values[:password])
    assert_not user.authenticate(values[:password].strip)
    assert_not_equal values[:password], user.password_digest
    assert user.must_change_password
    assert_not_includes user.inspect, user.password_digest
    assert_not User.column_names.include?("password")
    assert_not User.column_names.include?("password_confirmation")
  end

  test "invalid identity roles states password sizes Unicode and confirmation are rejected" do
    [ { name: "" }, { name: "a " }, { name: "Nome\ninválido" }, { name: "x"*101 }, { email: "" }, { email: "invalid" }, { email: "x"*255 }, { role: "root" }, { active: nil },
      { password: "short" }, { password: "é"*37, password_confirmation: "é"*37 }, { password: "x"*73, password_confirmation: "x"*73 }, { password: "a\0b#{'x'*12}" }, { password_confirmation: nil }, { password_confirmation: "different" } ].each do |values|
      user=User.new(user_attributes(**values))
      assert_not user.valid?, values.keys.inspect
    end
    user=User.new(user_attributes(password: "é"*36, password_confirmation: "é"*36))
    assert user.valid?, user.errors.map(&:message).join
    inactive=User.new(user_attributes(active: false))
    assert_not inactive.valid?
    inactive.deactivated_at=Time.current
    assert inactive.valid?
    invalid=User.new(user_attributes(active: "anything"))
    assert_not invalid.valid?
  end

  test "PostgreSQL functional uniqueness and checks cannot be bypassed by direct updates" do
    user=create_user
    second=create_user
    attempts=[
      [ ActiveRecord::RecordNotUnique, { email: user.email.upcase } ],
      [ ActiveRecord::StatementInvalid, { role: "root" } ],
      [ ActiveRecord::StatementInvalid, { active: false, deactivated_at: nil } ],
      [ ActiveRecord::StatementInvalid, { active: true, deactivated_at: Time.current } ],
      [ ActiveRecord::StatementInvalid, { lock_version: -1 } ],
      [ ActiveRecord::NotNullViolation, { password_digest: nil } ]
    ]
    attempts.each do |type, values|
      assert_raises(type) { User.transaction(requires_new: true) { User.where(id: second.id).update_all(values) } }
    end
    assert_not User.new(user_attributes(email: user.email.upcase)).valid?
  end

  test "optimistic locking rejects stale native writes" do
    user=create_user
    stale=User.find(user.id)
    user.update!(name: "Nome atualizado")
    assert_equal 1, user.lock_version
    assert_raises(ActiveRecord::StaleObjectError) { stale.update!(name: "Nome antigo") }
  end
end
