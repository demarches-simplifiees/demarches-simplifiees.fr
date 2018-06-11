# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)

Rails.application.load_tasks

desc "Create a test account that includes all roles"
task :create_test_account => :environment do
  email, password = nil
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: rake create_test_account -- --email=EMAIL --password=PASSWORD"
    opts.on("--email ARG",    String) { |e| email = e }
    opts.on("--password ARG", String) { |p| password = p }
  end
  args = optparse.order!(ARGV) {}
  optparse.parse!(args)

  raise optparse.banner if email.nil? || password.nil?
  raise "Password must be at least 8 characters." if password.length < 8

  Administration.create!(email: email, password: password)
  Administrateur.create!(email: email, password: password)
  Gestionnaire.create!(email: email, password: password)
  User.create!(email: email, password: password, confirmed_at: DateTime.now)
  puts "Test account #{email} created"
end

task :deploy do
  domains = %w(37.187.249.111 149.202.72.152 149.202.198.6)
  domains.each do |domain|
    sh "mina deploy domain=#{domain}"
  end
end

task :deploy_ha do
  domains = %w(149.202.72.152 149.202.198.6)
  domains.each do |domain|
    sh "mina deploy domain=#{domain}"
  end
end

task :deploy_old do
  domains = %w(37.187.154.237 37.187.249.111)
  domains.each do |domain|
    sh "mina deploy domain=#{domain}"
  end
end

task :deploy_test do
  domains = %w(192.168.0.116)
  branch = 'clamav'
  domains.each do |domain|
    sh "mina deploy domain=#{domain} branch=#{branch}"
  end
end
