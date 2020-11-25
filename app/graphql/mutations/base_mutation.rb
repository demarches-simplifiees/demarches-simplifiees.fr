module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    def validate_blob(blob_id)
      if blob_id.present?
        begin
          blob = ActiveStorage::Blob.find_signed(blob_id)
          blob.identify
          nil
        rescue ActiveStorage::FileNotFoundError
          return { errors: ['Le fichier n’a pas été correctement téléversé sur le serveur de stockage'] }
        rescue ActiveSupport::MessageVerifier::InvalidSignature
          return { errors: ['L’identifiant du fichier téléversé est invalide'] }
        end
      end
    end
  end
end
