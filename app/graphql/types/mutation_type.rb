module Types
  class MutationType < Types::BaseObject
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload

    field :dossier_envoyer_message, mutation: Mutations::DossierEnvoyerMessage
    field :dossier_passer_en_instruction, mutation: Mutations::DossierPasserEnInstruction
    field :dossier_classer_sans_suite, mutation: Mutations::DossierClasserSansSuite
    field :dossier_refuser, mutation: Mutations::DossierRefuser
    field :dossier_accepter, mutation: Mutations::DossierAccepter
  end
end
