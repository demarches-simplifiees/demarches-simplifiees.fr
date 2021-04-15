module Mutations
  class DossierModifierAnnotationText < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format text."

    argument :value, String, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(
        :text,
        dossier,
        annotation_id,
        instructeur,
        value
      )
    end
  end
end
