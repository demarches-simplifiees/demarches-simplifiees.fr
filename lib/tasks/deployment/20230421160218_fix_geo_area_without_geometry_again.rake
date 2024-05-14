# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_geo_area_without_geometry_again'
  task fix_geo_area_without_geometry_again: :environment do
    puts "Running deploy task 'fix_geo_area_without_geometry_again'"

    Rake::Task['after_party:fix_geo_area_without_geometry'].invoke

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
