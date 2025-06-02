# frozen_string_literal: true

namespace :s3 do
  desc 'synchronize current storage to other one (local, s3)'
  task sync: :environment do
    S3Synchronization.synchronize(true, nil)
  end
end
