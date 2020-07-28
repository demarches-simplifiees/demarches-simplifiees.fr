module Mutations
  class DossierModifierAnnotationCheckbox < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format oui/non."

    argument :value, Boolean, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(
        :checkbox,
        dossier,
        annotation_id,
        instructeur,
        value
      ) do |type_champ, value|
        if type_champ == TypeDeChamp.type_champs.fetch(:yes_no)
          value ? 'true' : 'false'
        else
          value ? 'on' : 'off'
        end
      end
    end
  end
end
