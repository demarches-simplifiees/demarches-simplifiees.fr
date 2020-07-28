module Mutations
  class DossierModifierAnnotationIntegerNumber < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format nombre entier."

    argument :value, Int, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(
        :integer_number,
        dossier,
        annotation_id,
        instructeur,
        value
      )
    end
  end
end
