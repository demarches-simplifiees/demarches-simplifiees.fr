# frozen_string_literal: true

module Mutations
  class DossierModifierAnnotationText < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format text."

    argument :value, String, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(dossier:, annotation_id:, instructeur:, value:)
    end

    private

    def input_type
      :text
    end
  end
end
