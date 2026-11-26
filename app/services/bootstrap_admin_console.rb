require "io/console"

class BootstrapAdminConsole
  def self.run(input: $stdin, output: $stdout)
    if User.where(role: "admin").exists?
      output.puts "A inicialização já foi realizada. Nenhuma conta foi alterada."
      return true
    end
    unless input.tty? && input.respond_to?(:noecho)
      output.puts "Execute a tarefa em um terminal interativo com entrada de senha sem eco."
      return false
    end
    values = {}
    { name: "Nome", email: "E-mail", password: "Senha", password_confirmation: "Confirmação da senha" }.each do |key, label|
      output.print "#{label}: "
      output.flush
      line = %i[password password_confirmation].include?(key) ? input.noecho(&:gets) : input.gets
      output.puts if %i[password password_confirmation].include?(key)
      return false unless line
      values[key] = line.chomp
    end
    operation = ManageUser.new(action: "bootstrap", attributes: values)
    if operation.call
      output.puts(operation.already_initialized ? "A inicialização já foi realizada." : "Administrador inicial criado com sucesso.")
      true
    else
      operation.errors.each { |error| output.puts error.message }
      false
    end
  rescue ActiveRecord::ActiveRecordError
    output.puts "Não foi possível concluir a inicialização. Tente novamente."
    false
  end
end
