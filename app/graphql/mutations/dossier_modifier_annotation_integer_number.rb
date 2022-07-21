module Mutations
  class DossierModifierAnnotationIntegerNumber < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format nombre entier."

    argument :value, Int, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(
        dossier: dossier,
        annotation_id: annotation_id,
        instructeur: instructeur,
        value: value
      )
    end

    private

    def input_type
      :integer_number
    end
  end
end
