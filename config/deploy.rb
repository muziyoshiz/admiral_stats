# config valid only for current version of Capistrano
lock '3.8.2'

set :application, 'admiral_stats'
set :repo_url, 'git@github.com:muziyoshiz/admiral_stats.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for linked_dirs is []
# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# use /usr/local/rvm
set :rvm_type, :system

# web role のマシンで asset:precompile を実行
set :assets_roles, [ :web ]
# 保存する asset バージョン数
set :keep_assets, 2

# デプロイ時に、deployment グループの gem も除外する
set :bundle_without, %w{development test deployment}.join(' ')

# Passenger (mod_rails) をアップロードするために restart.txt を配置
namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end
end

after 'deploy:publishing', 'deploy:restart'
