require "test_helper"
require_relative "../support/user_data"

class BootstrapAdminConsoleTest < ActiveSupport::TestCase
  include UserData
  class Terminal < StringIO
    attr_reader :hidden_reads
    def tty?; true; end
    def noecho
      @hidden_reads=(@hidden_reads||0)+1
      yield self
    end
  end

  test "bootstrap hides both password entries and repeated runs never overwrite or reactivate" do
    secret="Senha fictícia para teste!"
    input=Terminal.new("Admin de teste\nADMIN@EXAMPLE.TEST\n#{secret}\n#{secret}\n")
    output=StringIO.new
    assert BootstrapAdminConsole.run(input: input, output: output)
    assert_equal 2, input.hidden_reads
    user=User.find_by!(email: "admin@example.test")
    assert user.authenticate(secret)
    assert_equal "admin", user.role
    assert user.active
    digest=user.password_digest
    assert_not_includes output.string, secret
    assert_not_includes output.string, digest
    assert_difference "User.count", 0 do
      assert BootstrapAdminConsole.run(input: Terminal.new(""), output: output)
    end
    assert_equal digest, user.reload.password_digest
    assert_equal 1, AuditEvent.where(action: "user_created", entity_type: "User").count
  end

  test "bootstrap rejects non interactive and invalid input without accounts or credentials in output" do
    output=StringIO.new
    assert_not BootstrapAdminConsole.run(input: StringIO.new(""), output: output)
    input=Terminal.new("a\ninvalid\nshort\ndifferent\n")
    assert_no_difference "User.count" do
      assert_not BootstrapAdminConsole.run(input: input, output: output)
    end
    assert_not_includes output.string, "short"
    assert_not_includes output.string, "different"
  end
end
