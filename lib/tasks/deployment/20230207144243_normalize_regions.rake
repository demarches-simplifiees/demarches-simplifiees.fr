# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: normalize_regions'
  task normalize_regions: :environment do
    puts "Running deploy task 'normalize_regions'"

    scope_external_id_nil = Champs::RegionChamp.where(external_id: nil)
    scope_external_id_empty = Champs::RegionChamp.where(external_id: '')
    scope_external_id_present = Champs::RegionChamp.where.not(external_id: [nil, ''])

    progress = ProgressReport.new(scope_external_id_nil.count + scope_external_id_empty.count + scope_external_id_present.count)

    scope_external_id_nil.find_each do |champ|
      progress.inc

      if champ.value == ''
        champ.update_columns(value: nil)
      elsif champ.value == "Provence-Alpes-Côte d'Azur"
        champ.update_columns(external_id: "93", value: "Provence-Alpes-Côte d’Azur")
      elsif champ.present?
        champ.update_columns(external_id: APIGeoService.region_code(champ.value))
      end
    end

    scope_external_id_empty.find_each do |champ|
      progress.inc

      if champ.value.nil?
        champ.update_columns(external_id: nil)
      elsif champ.value == ''
        champ.update_columns(external_id: nil, value: nil)
      elsif champ.value == "Provence-Alpes-Côte d'Azur"
        champ.update_columns(external_id: "93", value: "Provence-Alpes-Côte d’Azur")
      elsif champ.present?
        champ.update_columns(external_id: APIGeoService.region_code(champ.value))
      end
    end

    scope_external_id_present.find_each do |champ|
      progress.inc

      if champ.value.blank?
        champ.update_columns(value: APIGeoService.region_name(champ.external_id))
      elsif champ.value == "Provence-Alpes-Côte d'Azur"
        champ.update_columns(external_id: "93", value: "Provence-Alpes-Côte d’Azur")
      end
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
