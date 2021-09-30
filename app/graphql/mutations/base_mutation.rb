module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    private

    def validate_blob(blob_id)
      begin
        blob = ActiveStorage::Blob.find_signed(blob_id)
        raise ActiveSupport::MessageVerifier::InvalidSignature if blob.nil?

        # open downloads the file and checks its hash
        blob.open { |f| }
        true
      rescue ActiveStorage::FileNotFoundError
        return false, { errors: ['Le fichier n’a pas été correctement téléversé sur le serveur de stockage'] }
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        return false, { errors: ['L’identifiant du fichier téléversé est invalide'] }
      rescue ActiveStorage::IntegrityError
        return false, { errors: ['Le hash du fichier téléversé est invalide'] }
      end
    end

    def dossier_authorized_for?(dossier, instructeur)
      if instructeur.is_a?(Instructeur) && instructeur.dossiers.exists?(id: dossier.id)
        true
      else
        return false, { errors: ['L’instructeur n’a pas les droits d’accès à ce dossier'] }
      end
    end
  end
end
