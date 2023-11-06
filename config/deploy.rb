# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"
load 'config/deploy/recipes/redis.rb'

set :application, "chowmill"
set :repo_url, "git@bitbucket.org:chowmillians/chowmill.git"

set :user,            'ubuntu'
set :puma_threads,    [4, 16]
set :puma_workers,    0

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/home/ubuntu/chowmill"
set :deploy_to,       "/home/#{fetch(:user)}/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
# set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to true if using ActiveRecord
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true
set :pty, false

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"
# set :linked_files, fetch(:linked_files, []).concat(%w{.env config/nginx.conf config/database.yml config/reports_database.yml})
set :linked_files, fetch(:linked_files, []).concat(%w{.env config/nginx.conf})

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
set :linked_dirs, fetch(:linked_dirs, []).concat(%w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system})

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :sidekiq do

  task :restart do
    invoke 'sidekiq:stop'
    invoke 'sidekiq:start' # NOTE: we are not starting sidekiq here because monit is up doing so
  end

  task :stop do
    on roles(:app) do
      within release_path do
        execute :bundle, "exec sidekiqctl stop tmp/pids/sidekiq-0.pid 0 -e #{fetch(:stage)}"
      end
    end
  end

  task :start do
    on roles(:app) do
      within release_path do
        # execute :bundle, "exec sidekiq -d -L log/sidekiq.log -C config/sidekiq.yml -e #{fetch(:stage)}"
        execute :bundle, "exec sidekiq -e #{fetch(:stage)} -d -L #{shared_path}/log/sidekiq.log -C /home/ubuntu/chowmill/current/config/sidekiq.yml -P #{shared_path}/tmp/pids/sidekiq-0.pid"
      end
    end
  end
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      # unless `git rev-parse HEAD` == `git rev-parse origin/master`
      #   puts "WARNING: HEAD is not the same as origin/master"
      #   puts "Run `git push` to sync changes."
      #   exit
      # end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
      invoke 'sidekiq:restart'
    end
  end

  before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :restart
end

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma
