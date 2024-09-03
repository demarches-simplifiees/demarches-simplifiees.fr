# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: use_jsonb_in_geo_areas_properties'
  task use_jsonb_in_geo_areas_properties: :environment do
    puts "Running deploy task 'use_jsonb_in_geo_areas_properties'"

    geo_areas = GeoArea.where("properties::text LIKE ?", "%--- !ruby%")
    progress = ProgressReport.new(geo_areas.count)
    geo_areas.find_each do |geo_area|
      geo_area.properties = geo_area.properties
      if !geo_area.save
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
