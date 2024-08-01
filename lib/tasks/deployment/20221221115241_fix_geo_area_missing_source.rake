# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_geo_area_missing_source'
  task fix_geo_area_missing_source: :environment do
    puts "Running deploy task 'fix_geo_area_missing_source'"

    geo_areas = GeoArea.where(source: nil)
    progress = ProgressReport.new(geo_areas.count)
    geo_areas.find_each do |geo_area|
      geo_area.source = GeoArea.sources.fetch(:selection_utilisateur)
      geo_area.save!

      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
