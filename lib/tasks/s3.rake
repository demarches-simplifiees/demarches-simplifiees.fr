namespace :s3 do
  desc 'synchronize local storage to s3'
  task sync: :environment do
    puts "Synchronizing local storage files to s3"
    $running_via_rake = true

    S3Synchronization.synchronize(nil)
  end
end
