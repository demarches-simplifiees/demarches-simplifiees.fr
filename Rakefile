# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)

Rails.application.load_tasks

task :lint do
  sh "bundle exec rubocop"
  sh "bundle exec haml-lint app/views/"
  sh "bundle exec scss-lint app/assets/stylesheets/"
  sh "bundle exec brakeman --no-pager"
  sh "yarn lint:js"
end

task :deploy_ha do
  domains = %w(149.202.72.152 149.202.198.6)
  domains.each do |domain|
    sh "mina deploy domain=#{domain}"
  end
end
