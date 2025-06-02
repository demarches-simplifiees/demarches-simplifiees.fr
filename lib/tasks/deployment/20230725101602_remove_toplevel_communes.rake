# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_toplevel_communes'
  task remove_toplevel_communes: :environment do
    puts "Running deploy task 'remove_toplevel_communes'"

    communes = Champs::CommuneChamp.where(external_id: ['75056', '13055', '69123'])
    progress = ProgressReport.new(communes.count)

    communes.find_each do |commune|
      external_id = case commune.external_id
      when '75056'
        '75101'
      when '13055'
        '13201'
      when '69123'
        '69381'
      end
      commune.update_columns(external_id:, value: APIGeoService.commune_name(commune.code_departement, external_id))
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
