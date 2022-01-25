namespace :after_party do
  desc 'Deployment task: populate_zones'
  task populate_zones: :environment do
    puts "Running deploy task 'populate_zones'"

    Zone.create!(acronym: 'COLLECTIVITE', label: 'Collectivité territoriale')
    config = Psych.safe_load(File.read(Rails.root.join("config", "zones.yml")))
    config["ministeres"].each do |ministere|
      acronym = ministere.keys.first
      Zone.create!(acronym: acronym, label: ministere["label"])
    end
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
