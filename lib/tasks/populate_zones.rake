namespace :zones do
  task populate_zones: :environment do
    puts "Running deploy task 'populate_zones'"

    collectivite = Zone.find_or_create_by!(acronym: 'COLLECTIVITE')
    coll_label = collectivite.labels.find_or_initialize_by(designated_on: Date.parse('1977-07-30'))
    coll_label.update(name: 'Collectivité territoriale')

    config = Psych.safe_load(File.read(Rails.root.join("config", "zones.yml")))
    config["ministeres"].each do |ministere|
      acronym = ministere.keys.first
      zone = Zone.find_or_create_by!(acronym: acronym)
      labels_a = ministere[acronym]
      labels_a.each do |label_h|
        designated_on = label_h.keys.first
        label = zone.labels.find_or_initialize_by(designated_on: designated_on)
        label.update(name: label_h[designated_on])
      end
    end
  end
end
