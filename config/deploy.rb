require 'mina/bundler'
require 'mina/git'
require 'mina/rails'
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
#   shared_dirs   - Manually create these paths in shared/ on your server.
#                   They will be linked in the 'deploy:link_shared_paths' step.

deploy_to = '/var/www/ds'
shared_dirs = [
  'log',
  'sockets',
  'tmp/cache',
  'tmp/pids',
  'vendor/bundle'
]

set :domain, ENV.fetch('domain')
set :deploy_to, deploy_to
set :repository, 'https://github.com/betagouv/demarches-simplifiees.fr.git'
set :branch, ENV.fetch('branch')
set :forward_agent, true
set :user, 'ds'
set :shared_dirs, shared_dirs
set :rbenv_path, "/home/ds/.rbenv/bin/rbenv"

puts "Deploy to #{ENV.fetch('domain')}, branch: #{ENV.fetch('branch')}"

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :setup do
  shared_dirs.each do |dir|
    command %[mkdir -p "#{deploy_to}/shared/#{dir}"]
    command %[chmod g+rx,u+rwx "#{deploy_to}/shared/#{dir}"]
  end
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
      echo "-----> Running after_party"
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
    }
  end

  desc "Reload nginx"
  task :reload_nginx do
    command %{
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
    invoke :'rails:assets_precompile'

    on :launch do
      invoke :'service:restart_puma'
      invoke :'service:reload_nginx'
      invoke :'service:restart_delayed_job'
      invoke :'deploy:cleanup'
    end
  end
end

task :post_deploy do
  command 'export PATH=$PATH:/home/ds/.rbenv/bin:/home/ds/.rbenv/shims'
  command 'source /home/ds/.profile'
  command 'cd /home/ds/current'

  invoke :'after_party:run'
end
