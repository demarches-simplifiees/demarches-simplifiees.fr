# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: populate_zones_with_tchap_hs'
  task populate_zones_with_tchap_hs: :environment do
    puts "Running deploy task 'populate_zones_with_tchap_hs'"
    collectivite = Zone.find_or_create_by!(acronym: 'COLLECTIVITE')
    coll_label = collectivite.labels.find_or_initialize_by(designated_on: Date.parse('1977-07-30'))
    coll_label.update(name: 'Collectivité territoriale')

    config = Psych.safe_load(Rails.root.join("config", "zones.yml").read)
    config["ministeres"].each do |ministere|
      acronym = ministere.keys.first
      zone = Zone.find_or_create_by!(acronym: acronym)
      labels_a = ministere['labels']
      labels_a.each do |label_h|
        designated_on = label_h.keys.first
        label = zone.labels.find_or_initialize_by(designated_on: designated_on)
        label.update(name: label_h[designated_on])
      end
      zone.update(tchap_hs: ministere['tchap_hs']) if ministere['tchap_hs']
    end

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
