# frozen_string_literal: true

module Maintenance
  class UpdateZonesTask < MaintenanceTasks::Task
    def collection
      config = Psych.safe_load(Rails.root.join("config", "zones.yml").read)
      config['ministeres']
    end

    def process(ministere)
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

    def count
      collection.length
    end
  end
end
