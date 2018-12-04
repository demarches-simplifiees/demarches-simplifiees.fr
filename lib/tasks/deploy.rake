def domains_for_stage(stage)
  case stage
  when 'dev'
    ['web1.dev', 'web2.dev']
  when 'prod'
    ['web1', 'web2']
  else
    raise "STAGE #{stage} is unknown. It must be either dev or prod."
  end
end

task :setup do
  domains = domains_for_stage(ENV.fetch('STAGE'))

  domains.each do |domain|
    sh "mina setup domain=#{domain} force_asset_precompile=true"
  end
end

task :deploy do
  domains = domains_for_stage(ENV.fetch('STAGE'))
  branch = ENV.fetch('BRANCH')

  domains.each do |domain|
    sh "mina deploy domain=#{domain} branch=#{branch} force_asset_precompile=true"
  end
end

task :post_deploy do
  domains = domains_for_stage(ENV.fetch('STAGE'))
  branch = ENV.fetch('BRANCH')

  sh "mina post_deploy domain=#{domains.first} branch=#{branch}"
end
