module Types
  class MutationType < Types::BaseObject
    field :dossier_passer_en_instruction, mutation: Mutations::DossierPasserEnInstructionMutation
    field :dossier_repasser_en_construction, mutation: Mutations::DossierRepasserEnConstructionMutation

    field :dossier_accepter, mutation: Mutations::DossierAccepterMutation
    field :dossier_classer_sans_suite, mutation: Mutations::DossierClasserSansSuiteMutation
    field :dossier_refuser, mutation: Mutations::DossierRefuserMutation
  end
end
