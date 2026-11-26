namespace :users do
  desc "Cria o primeiro administrador com senha digitada sem eco"
  task bootstrap_admin: :environment do
    abort "A inicialização não foi concluída." unless BootstrapAdminConsole.run
  end
end
