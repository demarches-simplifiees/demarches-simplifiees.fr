def domains_from_env(env)
  case env
  when 'dev'
    ['web1.dev', 'web2.dev']
  when 'prod'
    ['web1', 'web2']
  else
    raise "STAGE #{env} is unknown. It must be either dev or prod"
  end
end

task :deploy do
  domains = domains_from_env(ENV['STAGE'])
  branch = ENV['BRANCH'] || 'dev'

  domains.each do |domain|
    sh "mina deploy domain=#{domain} branch=#{branch} force_asset_precompile=true"
  end
end

task :setup do
  domains = ['web1', 'web2']
  domains.each do |domain|
    sh "mina setup domain=#{domain} force_asset_precompile=true"
  end
end

task :setup_dev do
  domains = ['web1.dev', 'web2.dev']
  domains.each do |domain|
    sh "mina setup domain=#{domain} force_asset_precompile=true"
  end
end
