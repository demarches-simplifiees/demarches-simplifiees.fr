# frozen_string_literal: true

def domains_for_stage
  if ENV['DOMAINS'].present?
    ENV['DOMAINS'].split
  else
    raise "DOMAINS is empty. It must be something like DOMAINS='web1.dev web2.dev'"
  end
end

task :setup do
  domains = domains_for_stage

  domains.each do |domain|
    sh "mina setup domain=#{domain}"
  end
end

task :deploy do
  domains = domains_for_stage
  branch = ENV.fetch('BRANCH')

  domains.each do |domain|
    sh "mina deploy domain=#{domain} branch=#{branch} force_asset_precompile=true"
  end
end

task :post_deploy do
  domains = domains_for_stage
  branch = ENV.fetch('BRANCH')

  sh "mina post_deploy domain=#{domains.first} branch=#{branch}"
end

task :rollback do
  domains = domains_for_stage
  branch = ENV.fetch('BRANCH')

  domains.each do |domain|
    sh "mina rollback service:restart_puma service:reload_nginx service:restart_delayed_job domain=#{domain} branch=#{branch}"
  end
end
