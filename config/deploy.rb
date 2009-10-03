set :application, "weather"
set :domain, "matthew@squeeze"
set :deploy_to, "/var/www/weather"
set :repository, "git://github.com/mholling/weather.git"
set :revision, "master"
set :web_command, "sudo apache2ctl"
 
set(:db_user) do
  print "Enter the database user name: "
  STDOUT.flush
  STDIN.gets.chomp
end
 
set(:db_password) do
  print "Enter the database user password: "
  STDOUT.flush
  STDIN.gets.chomp
end
 
namespace :vlad do
  namespace :yaml do
    desc "Generate database.yml in shared directory."
    remote_task :database do
      require 'tempfile'
      file = Tempfile.new("database.yml")
      file.print %{
production:
  database: #{application}
  adapter: mysql
  encoding: utf8
  socket: /var/run/mysqld/mysqld.sock
  username: #{db_user}
  password: #{db_password}
      }
      file.flush
      run "mkdir -p #{shared_path}/config && chmod 775 #{shared_path}/config && rm -f #{shared_path}/config/database.yml"
      rsync file.path, "#{shared_path}/config/database.yml"
    end
    
    desc "Generate application.yml in config directory."
    remote_task :application do
      rsync "config/application.yml", "#{current_path}/config/application.yml"
    end
  end
  
  desc "Symlink database.yml file."
  remote_task :symlink do
    run "ln -nfs #{shared_path}/config/database.yml #{current_path}/config/database.yml"
    # run "ln -nfs #{current_path}/public #{current_path}/public/add_expires_header"
  end
 
  desc "Create database.yml in shared directory."
  task :setup do
    Rake::Task["vlad:yaml:database"].invoke
  end
  
  namespace :daemon do
    desc "Stop weather daemon."
    remote_task :stop do
      run "sudo monit stop weather"
    end
    
    desc "Start weather daemon."
    remote_task :start do
      run "sudo monit start weather"
    end
  end
  
  desc "Deploy application."
  task :deploy => [ "vlad:daemon:stop", "vlad:update", "vlad:symlink", "vlad:yaml:application", "vlad:migrate", "vlad:start_app", "vlad:daemon:start" ]
  
end