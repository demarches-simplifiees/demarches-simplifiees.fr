module Types
  class MutationType < Types::BaseObject
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload

    field :dossier_envoyer_message, mutation: Mutations::DossierEnvoyerMessage
  end
end
