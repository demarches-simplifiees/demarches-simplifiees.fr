module Recovery
  class Importer
    attr_reader :dossiers

    def initialize(file_path: Recovery::Exporter::FILE_PATH)
      @dossiers = Marshal.load(File.read(file_path))
    end

    def load
      @dossiers.map do |dossier|
        dossier.instance_variable_set :@new_record, true

        Dossier.insert(dossier.attributes)

        Etablissement.insert(dossier.etablissement.attributes)
        if dossier.etablissement.present?
          APIEntreprise::EntrepriseJob.perform_later(dossier.etablissement.id, dossier.procedure.id)
        end

        Individual.insert(dossier.individual.attributes)

        dossier.invites.each do |invite|
          Invite.insert(invite.attributes)
        end

        dossier.traitements.each do |traitement|
          Traitement.insert(traitement.attributes)
        end

        dossier.transfer_logs.each do |transfer|
          DossierTransferLog.insert(transfer.attributes)
        end

        dossier.etablissement.exercices.each do |exercice|
          Exercice.insert(exercice.attributes)
        end

        dossier.commentaires.each do |commentaire|
          Commentaire.insert(commentaire.attributes)
          if commentaire.piece_jointe.attached?
            import(commentaire.piece_jointe)
          end
        end

        dossier.avis.each do |avis|
          Avis.insert(avis.attributes)

          if avis.introduction_file.attached?
            import(avis.introduction_file)
          end

          if avis.piece_justificative_file.attached?
            import(avis.piece_justificative_file)
          end
        end

        dossier.dossier_operation_logs.each do |dol|
          DossierOperationLog.insert(dol.attributes)

          if dol.serialized.attached?
            import(dol.serialized)
          end
        end

        if dossier.attestation.present?
          Attestation.insert(dossier.attestation.attributes)
          import(dossier.attestation.pdf)
        end

        if dossier.justificatif_motivation.attached?
          import(dossier.justificatif_motivation)
        end

        dossier.champs.each do |champ|
          champ.piece_justificative_file.each { |pj| import(pj) }

          if champ.etablissement.present?
            APIEntreprise::EntrepriseJob.perform_later(champ.etablissement.id, dossier.procedure.id)

            champ.etablissement.exercices.each do |exercice|
              Exercice.insert(exercice.attributes)
            end

            Etablissement.insert(champ.etablissement.attributes)
          end

          Champ.insert(champ.attributes)

          if champ.geo_areas.present?
            champ.geo_areas.each { GeoArea.insert(_1.attributes) }
          end
        end
      end
    end

    def import(pj)
      ActiveStorage::Blob.insert(pj.blob.attributes)
      ActiveStorage::Attachment.insert(pj.attributes)
    end
  end
end
