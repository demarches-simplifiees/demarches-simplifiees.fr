namespace :after_party do
  desc 'Deployment task: migrate_geo_area_data'
  task migrate_geo_area_data: :environment do
    puts "Running deploy task 'migrate_geo_area_data'"

    progress = ProgressReport.new(Champs::CarteChamp.count)

    Champs::CarteChamp.includes(:geo_areas).find_each do |champ|
      geo_area = champ.geo_areas.find(&:selection_utilisateur?)
      geo_json = champ.geo_json_from_value

      if geo_area.blank? && geo_json.present?
        GeoArea.create(
          champ: champ,
          geometry: geo_json,
          source: GeoArea.sources.fetch(:selection_utilisateur)
        )
        progress.inc
      end
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190731152733'
  end
end
