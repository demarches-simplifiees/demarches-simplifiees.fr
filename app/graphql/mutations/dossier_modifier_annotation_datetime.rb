module Mutations
  class DossierModifierAnnotationDatetime < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format date et heure."

    argument :value, GraphQL::Types::ISO8601DateTime, required: true

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
      :datetime
    end
  end
end
