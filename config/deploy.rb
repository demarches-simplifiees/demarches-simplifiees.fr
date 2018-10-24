require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'

# Basic settings:
#   domain        - The hostname to SSH to.
#   deploy_to     - Path to deploy into.
#   repository    - Git repo to clone from. (needed by mina/git)
#   branch        - Branch name to deploy. (needed by mina/git)
#
# Advanced settings:
#   forward_agent - SSH forward_agent
#   user          - Username in the server to SSH to

set :domain, ENV.fetch('domain')
set :repository, 'https://github.com/betagouv/tps.git'
deploy_to = '/var/www/ds'
set :deploy_to, deploy_to
set :user, 'ds'
set :branch, ENV.fetch('branch')

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_dirs, [
  'log',
  'sockets',
  'tmp/pids',
  'tmp/cache'
]

set :rbenv_path, "/home/ds/.rbenv/bin/rbenv"
set :forward_agent, true # SSH forward_agent.

puts "Deploy to #{ENV.fetch('domain')}, branch: #{ENV.fetch('branch')}"

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :setup do
  command %[mkdir -p "#{deploy_to}/shared/log"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  command %[mkdir -p "#{deploy_to}/shared/tmp/pids"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/pids"]

  command %[mkdir -p "#{deploy_to}/shared/tmp/cache"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/cache"]

  command %[mkdir -p "#{deploy_to}/shared/sockets"]
  command %[chmod g+rx,u+rwx "#{deploy_to}/shared/sockets"]
end

namespace :yarn do
  desc "Install package dependencies using yarn."
  task :install do
    command %{
      echo "-----> Installing package dependencies using yarn"
      #{echo_cmd %[yarn install --non-interactive]}
    }
  end
end

namespace :after_party do
  desc "Run after_party tasks."
  task :run do
    command %{
      echo "-----> Running deploy tasks"
      #{echo_cmd %[bundle exec rake after_party:run]}
    }
  end
end

namespace :service do
  desc "Restart puma"
  task :restart_puma do
    command %{
      echo "-----> Restarting puma service"
      #{echo_cmd %[sudo systemctl restart puma]}
      echo "-----> Reloading nginx service"
      #{echo_cmd %[sudo systemctl reload nginx]}
    }
  end

  desc "Restart delayed_job"
  task :restart_delayed_job do
    command %{
      echo "-----> Restarting delayed_job service"
      #{echo_cmd %[sudo systemctl restart delayed_job]}
    }
  end
end

desc "Deploys the current version to the server."
task :deploy do
  command 'export PATH=$PATH:/home/ds/.rbenv/bin:/home/ds/.rbenv/shims'
  command 'source /home/ds/.profile'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'

    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'yarn:install'
    invoke :'rails:db_migrate'
    invoke :'after_party:run'
    invoke :'rails:assets_precompile'

    on :launch do
      invoke :'service:restart_puma'
      invoke :'service:restart_delayed_job'
    end
  end
end
