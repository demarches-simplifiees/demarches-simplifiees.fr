task :deploy do
  domains = ['web1', 'web2']
  domains.each do |domain|
    sh "mina deploy domain=#{domain} force_asset_precompile=true"
  end
end

task :setup do
  domains = ['web1', 'web2']
  domains.each do |domain|
    sh "mina setup domain=#{domain} force_asset_precompile=true"
  end
end

task :deploy_dev do
  domains = ['web1.dev', 'web2.dev']
  domains.each do |domain|
    sh "mina deploy domain=#{domain} force_asset_precompile=true"
  end
end

task :setup_dev do
  domains = ['web1.dev', 'web2.dev']
  domains.each do |domain|
    sh "mina setup domain=#{domain} force_asset_precompile=true"
  end
end
