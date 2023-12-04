namespace :after_party do
  desc 'Deployment task: purge_invalid_geo_areas'
  task purge_invalid_geo_areas: :environment do
    puts "Running deploy task 'purge_invalid_geo_areas'"

    geo_areas = GeoArea.selections_utilisateur
    progress = ProgressReport.new(geo_areas.count)

    geo_areas.find_each do |geo_area|
      if !geo_area.valid?
        geo_area.destroy
      end
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
