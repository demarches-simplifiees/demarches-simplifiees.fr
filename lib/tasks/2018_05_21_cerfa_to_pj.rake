namespace :'2018_05_21_cerfa_to_pj' do
  task set: :environment do
    dossiers = Cerfa.includes(dossier: [:procedure]).all.reject(&:empty?).map(&:dossier).compact.uniq

    dossiers.group_by(&:procedure).each do |procedure, dossiers|
      if !procedure.types_de_champ.find_by(libelle: 'CERFA')
        type_de_champ = procedure.types_de_champ.create(
          type_champ: 'piece_justificative',
          libelle: 'CERFA'
        )
        dossiers.each do |dossier|
          cerfa = dossier.cerfa.last
          champ = type_de_champ.champ.create(dossier: dossier)
          response = Typhoeus.get(cerfa.content_url, timeout: 5)
          if response.success?
            champ.piece_justificative_file.attach(
              io: StringIO.new(response.body),
              filename: cerfa.content.filename
            )
          end
        end
      end
    end
  end
end
