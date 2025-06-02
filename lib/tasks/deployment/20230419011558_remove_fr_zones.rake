# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_fr_zones'
  task remove_fr_zones: :environment do
    puts "Running deploy task 'remove_fr_zones'"

    FIXED_ZONES = [
      'COMMUNE', 'Communes',
      'EPIC', 'Établissement public industriel et commercial',
      'EPA', 'Établissement public administratif'
    ]
    puts "Removing DS zones"
    config = Psych.safe_load(Rails.root.join("config", "zones.yml").read)
    fr_zones = config["ministeres"].map { |ministere| ministere.keys.first } + ['COLLECTIVITE', "MInArm", "EN", "SPM"]
    fr_zones.each { |acronym| zone = Zone.where(acronym: acronym).first; zone&.labels&.destroy_all; zone&.destroy; }

    puts "Adding pf zones maybe accidentally deleted by deletion of fr zones"
    FIXED_ZONES.each_slice(2).map do |acronym, libelle|
      collectivite = Zone.find_or_create_by!(acronym: acronym)
      coll_label = collectivite.labels.find_or_initialize_by(designated_on: Date.parse('1977-07-30'))
      coll_label.update(name: libelle)
    end

    config = Psych.safe_load(Rails.root.join("config", "zones_pf.yml").read)
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

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
