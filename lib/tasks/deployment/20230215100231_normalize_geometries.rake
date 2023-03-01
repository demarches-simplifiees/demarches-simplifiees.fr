namespace :after_party do
  desc 'Deployment task: normalize_geometries'
  task normalize_geometries: :environment do
    puts "Running deploy task 'normalize_geometries'"

    progress = ProgressReport.new(GeoArea.count)
    GeoArea.in_batches(of: 100) do |geo_areas|
      ids = geo_areas.ids
      Migrations::NormalizeGeoAreaJob.perform_later(ids)
      progress.inc(ids.size)
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
