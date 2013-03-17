require "bundler/capistrano"

set :deploy_via, :remote_cache
set :application, "roozer"
set :repository,  'git@github.com:andys/roozer.git'
set :deploy_to, "/home/ubuntu/roozer"
set :scm, :git
role :app
set :user, "ubuntu"
set :use_sudo, false
ssh_options[:keys] = [ENV["SSH_KEY"]] if ENV["SSH_KEY"]

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, :roles => :app do
    run "cd #{deploy_to}/current && sudo bundle exec foreman export upstart /etc/init -u ubuntu -a roozer"
  end

  desc "Start the application services"
  task :start, :roles => :app do
    sudo "start app"
  end

  desc "Stop the application services"
  task :stop, :roles => :app do
    sudo "stop app"
  end

  desc "Restart the application services"
  task :restart, :roles => :app do
    run "sudo restart app"
  end
end

task :after_symlink do
  run "ln -nfs #{shared_path}/servers.txt #{release_path}/db/servers.txt"
#  run "ln -nfs #{shared_path}/doozer_server.crt #{release_path}/db/doozer_server.crt"
#  run "ln -nfs #{shared_path}/doozer_server.key #{release_path}/db/doozer_server.key"
end

after "deploy:update", "foreman:export"
after "deploy:restart", "deploy:cleanup"
after "deploy:create_symlink", "after_symlink"
