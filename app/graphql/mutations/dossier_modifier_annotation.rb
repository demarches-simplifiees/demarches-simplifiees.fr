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
        ChampRevision.create_or_update_revision(annotation, instructeur.id)
        { annotation: }
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
      stable_id, row_id = Champ.decode_typed_id(annotation_id)
      type_de_champ = dossier.revision.types_de_champ
        .private_only
        .find_by(type_champ: annotation_type_champ, stable_id:)

      return nil if type_de_champ.nil?
      dossier.champ_for_update(type_de_champ, row_id)
    end

    def annotation_type_champ
      case input_type
      when :text
        [
          TypeDeChamp.type_champs.fetch(:text),
          TypeDeChamp.type_champs.fetch(:textarea),
          TypeDeChamp.type_champs.fetch(:drop_down_list),
          TypeDeChamp.type_champs.fetch(:email),
          TypeDeChamp.type_champs.fetch(:phone),
          TypeDeChamp.type_champs.fetch(:visa)
        ]
      when :checkbox
        [
          TypeDeChamp.type_champs.fetch(:checkbox),
          TypeDeChamp.type_champs.fetch(:yes_no)
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
