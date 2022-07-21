module Mutations
  class DossierModifierAnnotationCheckbox < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format oui/non."

    argument :value, Boolean, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(
        dossier: dossier,
        annotation_id: annotation_id,
        instructeur: instructeur,
        value: value
      ) do |annotation, value|
        annotation.value = if annotation.type_champ == TypeDeChamp.type_champs.fetch(:yes_no)
          value ? 'true' : 'false'
        else
          value ? 'on' : 'off'
        end
      end
    end

    private

    def input_type
      :checkbox
    end
  end
end
