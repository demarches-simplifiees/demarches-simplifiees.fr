namespace :hotfix do
  desc 'Fix dossiers attestations'
  task dossiers_attestations: :environment do
    dossiers = Dossier
      .joins(procedure: :attestation_template)
      .left_outer_joins(:attestation)
      .where(attestation_templates: { activated: true },
        attestations: { id: nil },
        state: "accepte")
      .where("dossiers.processed_at > '2022-01-24'")
    progress = ProgressReport.new(dossiers.count)

    dossiers.find_each do |dossier|
      if dossier.attestation.blank?
        dossier.attestation = dossier.build_attestation
        dossier.save!
      end
      progress.inc
    end
    progress.finish
  end
end
