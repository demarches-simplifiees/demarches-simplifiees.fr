namespace :zones do
  task populate_zones: :environment do
    puts "Running deploy task 'populate_zones'"

    Zone.create!(acronym: 'COLLECTIVITE', label: 'Collectivité territoriale')
    config = Psych.safe_load(File.read(Rails.root.join("config", "zones.yml")))
    config["ministeres"].each do |ministere|
      acronym = ministere.keys.first
      Zone.create!(acronym: acronym, label: ministere["label"])
    end
  end
end
