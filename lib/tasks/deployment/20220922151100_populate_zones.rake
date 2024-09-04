# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: populate_zones'
  task populate_zones: :environment do
    if Rails.application.config.ds_zonage_enabled
      puts "Running deploy task 'populate_zones'"
      collectivite = Zone.find_or_create_by!(acronym: 'COLLECTIVITE')
      coll_label = collectivite.labels.find_or_initialize_by(designated_on: Date.parse('1977-07-30'))
      coll_label.update(name: 'Collectivité territoriale')

      config = Psych.safe_load(Rails.root.join("config", "zones.yml").read)
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

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
