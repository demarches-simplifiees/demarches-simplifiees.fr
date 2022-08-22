module Mutations
  class DossierModifierAnnotation < Mutations::BaseMutation
    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :instructeur_id, ID, "Instructeur qui demande la modification.", required: true, loads: Types::ProfileType
    argument :annotation_id, ID, "Annotation ID", required: true

    field :annotation, Types::ChampType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve_with_type(dossier:, annotation_id:, instructeur:, value:)
      annotation = find_annotation(dossier, annotation_id)

      if annotation.nil?
        return { errors: ["L’annotation \"#{annotation_id}\" n’existe pas"] }
      end

      if block_given?
        yield annotation, value
      else
        annotation.value = value
      end

      if annotation.save
        dossier.log_modifier_annotation!(annotation, instructeur)

        { annotation: annotation }
      else
        { errors: annotation.errors.full_messages }
      end
    end

    def authorized?(dossier:, instructeur:, **args)
      dossier_authorized_for?(dossier, instructeur)
    end

    private

    def input_type
      :text
    end

    def find_annotation(dossier, annotation_id)
      stable_id, row = Champ.decode_typed_id(annotation_id)

      Champ.joins(:type_de_champ).find_by(type_de_champ: {
        type_champ: annotation_type_champ,
        stable_id: stable_id,
        private: true
      }, private: true, row: row, dossier: dossier)
    end

    def annotation_type_champ
      case input_type
      when :text
        [
          TypeDeChamp.type_champs.fetch(:text),
          TypeDeChamp.type_champs.fetch(:textarea)
        ]
      when :checkbox
        [
          TypeDeChamp.type_champs.fetch(:checkbox),
          TypeDeChamp.type_champs.fetch(:yes_no),
          TypeDeChamp.type_champs.fetch(:engagement)
        ]
      when :date
        TypeDeChamp.type_champs.fetch(:date)
      when :datetime
        TypeDeChamp.type_champs.fetch(:datetime)
      when :integer_number
        TypeDeChamp.type_champs.fetch(:integer_number)
      when :piece_justificative
        TypeDeChamp.type_champs.fetch(:piece_justificative)
      end
    end
  end
end
