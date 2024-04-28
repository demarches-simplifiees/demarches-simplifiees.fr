# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_invalid_geometries'
  task remove_invalid_geometries: :environment do
    puts "Running deploy task 'remove_invalid_geometries'"

    geo_areas = GeoArea.where(source: :selection_utilisateur).includes(champ: [:geo_areas, :type_de_champ])
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
