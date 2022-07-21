module Mutations
  class DossierModifierAnnotationDate < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format date."

    argument :value, GraphQL::Types::ISO8601Date, required: true

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
      :date
    end
  end
end
