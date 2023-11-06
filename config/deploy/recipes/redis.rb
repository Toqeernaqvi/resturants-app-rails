namespace :redis do

  %w[start stop restart].each do |command|
    desc "#{command} redis"
    task command do
      on roles(:web), in: :sequence, wait: 1 do
        execute :sudo, "redis-server --loglevel verbose --daemonize yes"
      end
    end
  end
  after "deploy:restart", 'redis:restart'
end