# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task :deploy do
  domains = %w(37.187.154.237 37.187.249.111)
  domains.each do |domain|
    sh "mina deploy domain=#{domain}"
  end
end

task :deploy_test do
  domains = %w(test_sgmap)
  branch = 'master'
  domains.each do |domain|
    sh "mina deploy domain=#{domain} branch=#{branch}"
  end
end
