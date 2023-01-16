module Types
  class MutationType < Types::BaseObject
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload

    field :dossier_envoyer_message, mutation: Mutations::DossierEnvoyerMessage
    field :dossier_passer_en_instruction, mutation: Mutations::DossierPasserEnInstruction
    field :dossier_classer_sans_suite, mutation: Mutations::DossierClasserSansSuite
    field :dossier_refuser, mutation: Mutations::DossierRefuser
    field :dossier_accepter, mutation: Mutations::DossierAccepter
    field :dossier_repasser_en_instruction, mutation: Mutations::DossierRepasserEnInstruction
    field :dossier_repasser_en_construction, mutation: Mutations::DossierRepasserEnConstruction
    field :dossier_archiver, mutation: Mutations::DossierArchiver
    field :dossier_changer_groupe_instructeur, mutation: Mutations::DossierChangerGroupeInstructeur

    field :dossier_modifier_annotation_text, mutation: Mutations::DossierModifierAnnotationText
    field :dossier_modifier_annotation_checkbox, mutation: Mutations::DossierModifierAnnotationCheckbox
    field :dossier_modifier_annotation_date, mutation: Mutations::DossierModifierAnnotationDate
    field :dossier_modifier_annotation_datetime, mutation: Mutations::DossierModifierAnnotationDatetime
    field :dossier_modifier_annotation_integer_number, mutation: Mutations::DossierModifierAnnotationIntegerNumber
    field :dossier_modifier_annotation_ajouter_ligne, mutation: Mutations::DossierModifierAnnotationAjouterLigne

    field :groupe_instructeur_modifier, mutation: Mutations::GroupeInstructeurModifier
    field :groupe_instructeur_creer, mutation: Mutations::GroupeInstructeurCreer
    field :groupe_instructeur_ajouter_instructeurs, mutation: Mutations::GroupeInstructeurAjouterInstructeurs
    field :groupe_instructeur_supprimer_instructeurs, mutation: Mutations::GroupeInstructeurSupprimerInstructeurs
    field :demarche_cloner, mutation: Mutations::DemarcheCloner
  end
end
