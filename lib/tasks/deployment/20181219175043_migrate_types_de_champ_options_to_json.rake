namespace :after_party do
  desc 'Deployment task: migrate_types_de_champ_options_to_json'
  task migrate_types_de_champ_options_to_json: :environment do
    puts "Running deploy task 'migrate_types_de_champ_options_to_json'"

    dirty_tdcs = TypeDeChamp.where.not(options: nil)
    progress = ProgressReport.new(dirty_tdcs.count)
    dirty_tdcs.find_each do |tdc|
      tdc.options_will_change!
      tdc.save
      progress.inc
    end
    progress.finish

    AfterParty::TaskRecord.create version: '20181219175043'
  end
end
