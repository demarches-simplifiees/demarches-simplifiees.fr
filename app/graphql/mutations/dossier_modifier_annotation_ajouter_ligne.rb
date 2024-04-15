module Mutations
  class DossierModifierAnnotationAjouterLigne < Mutations::BaseMutation
    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :instructeur_id, ID, "Instructeur qui demande la modification.", required: true, loads: Types::ProfileType
    argument :annotation_id, ID, "Annotation ID", required: true

    field :annotation, Types::Champs::RepetitionChampType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(dossier:, annotation_id:, instructeur:)
      annotation = find_annotation(dossier, annotation_id)

      if annotation.nil?
        return { errors: ["L’annotation \"#{annotation_id}\" n’existe pas"] }
      end

      annotation.add_row(dossier.revision)

      { annotation:, errors: nil }
    end

    def authorized?(dossier:, instructeur:, **args)
      dossier_authorized_for?(dossier, instructeur)
    end

    private

    def find_annotation(dossier, annotation_id)
      stable_id, _row_id = Champ.decode_typed_id(annotation_id)
      type_de_champ = dossier.revision.types_de_champ
        .private_only
        .find_by(type_champ: TypeDeChamp.type_champs.fetch(:repetition), stable_id:)

      return nil if type_de_champ.nil?
      dossier.project_champ(type_de_champ, nil)
    end
  end
end
