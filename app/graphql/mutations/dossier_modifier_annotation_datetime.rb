# frozen_string_literal: true

module Mutations
  class DossierModifierAnnotationDatetime < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format date et heure."

    argument :value, GraphQL::Types::ISO8601DateTime, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(dossier:, annotation_id:, instructeur:, value: value.iso8601(0))
    end

    private

    def input_type
      :datetime
    end
  end
end
