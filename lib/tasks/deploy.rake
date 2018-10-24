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
  domains = domains_from_env(ENV.fetch('STAGE'))
  branch = ENV.fetch('BRANCH')

  domains.each do |domain|
    sh "mina deploy domain=#{domain} branch=#{branch} force_asset_precompile=true"
  end
end

task :setup do
  domains = domains_from_env(ENV['STAGE'])

  domains.each do |domain|
    sh "mina setup domain=#{domain} force_asset_precompile=true"
  end
end
