namespace :s3 do
  desc 'synchronize local storage to s3'
  task sync: :environment do
    puts "Synchronizing local storage files to s3"

    S3Synchronization.synchronize(nil) # (Time.zone.now() + 10.hours)
  end
end
