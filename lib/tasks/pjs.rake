namespace :pjs do
  task stats: :environment do
  end

  desc <<~EOD
    bin/rake 'pjs:migrate['aa']'
    bin/rake 'pjs:migrate['aa-ab-ac']'
  EOD
  task :migrate, [:prefixes] => :environment do |_t, args|
    # [a-b] => "key LIKE 'a%' or key LIKE 'b%'"
    prefix_like_query = args[:prefixes]
      .split('-')
      .map { "key LIKE '#{_1}%'" }
      .join(' or ')

    blobs = ActiveStorage::Blob
      .where(prefix_like_query)
      .where.not("key LIKE '%/%'") # do not touch already moved blob

    blobs_count = blobs.count
    rake_puts "targeted prefix: #{args[:prefixes]}, #{blobs_count} blobs"

    blobs.in_batches { |batch| batch.ids.each { |id| PjsMigrationJob.perform_later(id) } }
  end
end
