namespace :after_party do
  desc 'Deployment task: split_geo_area_selection_multipolygons'
  task split_geo_area_selection_multipolygons: :environment do
    puts "Running deploy task 'split_geo_area_selection_multipolygons'"

    Champs::CarteChamp.where.not(value: ['', '[]']).includes(:geo_areas).find_each do |champ|
      if champ.send(:selection_utilisateur_legacy?)
        legacy_selection_utilisateur = champ.selections_utilisateur.first
        champ.send(:legacy_selections_utilisateur).each do |area|
          champ.geo_areas << area
        end
        legacy_selection_utilisateur.destroy
      end
    end

    AfterParty::TaskRecord.create version: '20200414104712'
  end
end
