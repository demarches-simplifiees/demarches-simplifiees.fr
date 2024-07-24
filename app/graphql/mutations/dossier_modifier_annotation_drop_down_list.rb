module Mutations
  class DossierModifierAnnotationDropDownList < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation d'un champs de type dropdown list."

    argument :value, GraphQL::Types::String, required: true

    def resolve(dossier:, annotation_id:, instructeur:, value:)
      resolve_with_type(dossier:, annotation_id:, instructeur:, value:)
    end

    private

    def input_type
      :drop_down_list
    end
  end
end
