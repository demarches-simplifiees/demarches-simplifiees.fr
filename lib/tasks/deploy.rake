task :deploy do
  domains = case ENV['STAGE_NAME']
  when 'dev'
    ['web1.dev', 'web2.dev']
  when 'master'
    ['web1', 'web2']
  else
    raise "STAGE_NAME #{STAGE_NAME} is unknown. It must be either dev or master"
  end

  branch = ENV['STAGE_NAME']

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
