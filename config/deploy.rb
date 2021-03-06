set :application, 'dor-scripts'
set :repo_url, 'https://github.com/sul-dlss/dor-scripts.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/opt/app/dor_services/dor-scripts'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :linked_dirs, %w(log vendor/bundle config/settings)
set :linked_files, %w(config/honeybadger.yml)

# update shared_configs before restarting app
before 'deploy:symlink:release', 'shared_configs:symlink'

set :honeybadger_env, fetch(:stage)
