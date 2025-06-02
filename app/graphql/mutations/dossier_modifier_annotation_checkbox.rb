# frozen_string_literal: true

module Mutations
  class DossierModifierAnnotationCheckbox < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format oui/non."

    argument :value, Boolean, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(dossier:, annotation_id:, instructeur:, value:) do |annotation, value|
        annotation.value = value ? 'true' : 'false'
      end
    end

    private

    def input_type
      :checkbox
    end
  end
end
