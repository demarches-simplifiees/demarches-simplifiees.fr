namespace :after_party do
  desc 'Deployment task: normalize_regions'
  task normalize_regions: :environment do
    puts "Running deploy task 'normalize_regions'"

    scope_external_id_blank_value_blank = Champs::RegionChamp.where(external_id: [nil, ''], value: [nil, ''])
    scope_value_blank = Champs::RegionChamp.where(value: [nil, '']).where.not(external_id: [nil, ''])
    scope_external_id_blank = Champs::RegionChamp.where(external_id: [nil, '']).where.not(value: [nil, ''])
    scope_provence = Champs::RegionChamp.where(value: "Provence-Alpes-Côte d'Azur")

    progress = ProgressReport.new(
      scope_external_id_blank_value_blank.count +
      scope_value_blank.count +
      scope_external_id_blank.count +
      scope_provence.count
    )

    scope_external_id_blank_value_blank.in_batches(of: 10_000) do |regions|
      progress.inc(regions.count)
      regions.update_all(external_id: nil, value: nil)
    end

    scope_value_blank.find_each do |champ|
      champ.update_columns(value: APIGeoService.region_name(champ.external_id))
      progress.inc
    end

    scope_external_id_blank.find_each do |champ|
      champ.update_columns(external_id: APIGeoService.region_code(champ.value))
      progress.inc
    end

    scope_provence.in_batches(of: 10_000) do |regions|
      progress.inc(regions.count)
      regions.update_all(external_id: "93", value: "Provence-Alpes-Côte d’Azur")
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
