namespace :'2018_04_04_fetch_etablissement_with_no_entreprise' do
  task fetch: :environment do
    dossiers = Entreprise.joins('LEFT JOIN etablissements et ON entreprises.id = et.entreprise_id')
      .where('et.id IS NULL')
      .map(&:dossier_id).map { |id| Dossier.unscoped.find_by(id: id) }.compact

    dossiers.each do |dossier|
      siret = dossier.entreprise.siret_siege_social

      puts "Fetch siret: #{siret} for dossier: #{dossier.id}"

      if siret
        EtablissementUpdateJob.perform_later(dossier, siret)
      end
    end
  end
end
