namespace :dev do
  def run_and_stop_if_error(cmd)
    sh cmd do |ok, res|
      if !ok
        abort "#{cmd} failed with result : #{res.exitstatus}"
      end
    end
  end

  task :import_db do
    filename = "tps_prod_#{1.day.ago.strftime("%d-%m-%Y")}.sql"
    local_file = "/tmp/#{filename}"

    if !File.exist?(local_file)
      run_and_stop_if_error "scp -C db1:/data/backup/#{filename} #{local_file}"
    end

    dev_env_param = "RAILS_ENV=development"

    Rake::Task["db:drop"].invoke(dev_env_param)
    Rake::Task["db:create"].invoke(dev_env_param)
    run_and_stop_if_error "psql tps_development -f #{local_file}"

    Rake::Task["db:migrate"].invoke(dev_env_param)
    Rake::Task["db:environment:set"].invoke(dev_env_param)
    Rake::Task["db:test:prepare"].invoke
  end

  task :console do
    exec("ssh tps@sgmap_production1 -t 'source /etc/profile && cd current && bundle exec rails c -e production'")
  end
end
