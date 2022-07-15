namespace :deploy do
  namespace :check do
    before :linked_files, :set_database_yml do
      on roles(:app), in: :sequence, wait: 10 do
        upload! 'config/database.yml', "#{shared_path}/config/database.yml"
      end
    end
  end
end

namespace :puma do
  namespace :systemd do
    desc 'Reload the puma service via systemd by sending USR1 (e.g. trigger a zero downtime deploy)'
    task :reload do
      on roles(fetch(:puma_role)) do
        if fetch(:puma_systemctl_user) == :system
          sudo "#{fetch(:puma_systemctl_bin)} reload-or-restart #{fetch(:puma_service_unit_name)}"
        else
          execute "#{fetch(:puma_systemctl_bin)}", "--user", "reload", fetch(:puma_service_unit_name)
          execute :loginctl, "enable-linger", fetch(:puma_lingering_user) if fetch(:puma_enable_lingering)
        end
      end
    end
  end
end

after 'deploy:finished', 'puma:systemd:reload'