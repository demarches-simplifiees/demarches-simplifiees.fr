task :deploy do
  domains = ['149.202.72.152', '149.202.198.6']
  domains.each do |domain|
    sh "mina deploy domain=#{domain}"
  end
end
