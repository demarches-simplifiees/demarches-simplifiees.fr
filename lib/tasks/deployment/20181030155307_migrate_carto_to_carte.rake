namespace :after_party do
  desc 'Deployment task: migrate_carto_to_carte'
  task migrate_carto_to_carte: :environment do
    def add_champ_carte_if_needed(procedure)
      champ_carte = procedure.types_de_champ_ordered.to_a.find do |type_de_champ|
        type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:carte)
      end

      if champ_carte
        puts "Procedure##{procedure.id} already migrated to use champ carte"
      else
        add_champ_carte(procedure)
      end
    end

    def add_champ_carte(procedure)
      qp = !!procedure.module_api_carto.quartiers_prioritaires
      ca = !!procedure.module_api_carto.cadastre

      puts "Creating champ carte on Procedure##{procedure.id} with qp:#{qp} and ca:#{ca}..."

      procedure.types_de_champ.update_all('order_place = order_place + 1')
      type_de_champ = procedure.types_de_champ.create(
        order_place: 0,
        libelle: 'Cartographie',
        type_champ: TypeDeChamp.type_champs.fetch(:carte),
        quartiers_prioritaires: qp,
        cadastres: ca,
        mandatory: true
      )

      procedure.dossiers.each do |dossier|
        champ = type_de_champ.champ.create(dossier: dossier, value: dossier.json_latlngs)

        if ca && !dossier.cadastres.empty?
          puts "Creating Cadastres on Dossier##{dossier.id}..."
          dossier.cadastres.each do |cadastre|
            champ.geo_areas.create(
              source: GeoArea.sources.fetch(:cadastre),
              geometry: cadastre.geometry,
              surface_intersection: cadastre.surface_intersection,
              surface_parcelle: cadastre.surface_parcelle,
              numero: cadastre.numero,
              feuille: cadastre.feuille,
              section: cadastre.section,
              code_dep: cadastre.code_dep,
              nom_com: cadastre.nom_com,
              code_com: cadastre.code_com,
              code_arr: cadastre.code_arr
            )
          end
        end

        if qp && !dossier.quartier_prioritaires.empty?
          puts "Creating Quartiers Prioritaires on Dossier##{dossier.id}..."
          dossier.quartier_prioritaires.each do |qp|
            champ.geo_areas.create(
              source: GeoArea.sources.fetch(:quartier_prioritaire),
              geometry: qp.geometry,
              code: qp.code,
              nom: qp.nom,
              commune: qp.commune
            )
          end
        end
      end

      procedure.module_api_carto.update(migrated: true)
    end

    Procedure.includes(:types_de_champ, dossiers: [:cadastres, :quartier_prioritaires])
      .joins(:module_api_carto)
      .where(module_api_cartos: { use_api_carto: true, migrated: nil })
      .find_each do |procedure|
        add_champ_carte_if_needed(procedure)
      end

    AfterParty::TaskRecord.create version: '20181030155307'
  end
end
