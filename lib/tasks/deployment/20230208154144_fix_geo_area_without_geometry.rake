# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_geo_area_without_geometry'
  task fix_geo_area_without_geometry: :environment do
    puts "Running deploy task 'fix_geo_area_without_geometry'"

    geo_areas = GeoArea.where(geometry: nil)

    geo_areas.find_each do |geo_area|
      geo_area.geometry = {}
      geo_area.save!
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
