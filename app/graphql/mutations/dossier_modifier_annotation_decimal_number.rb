# frozen_string_literal: true

module Mutations
  class DossierModifierAnnotationDecimalNumber < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format nombre decimal."

    argument :value, Float, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(dossier:, annotation_id:, instructeur:, value:)
    end

    private

    def input_type
      :decimal_number
    end
  end
end
