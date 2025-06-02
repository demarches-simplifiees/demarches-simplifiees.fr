# frozen_string_literal: true

module Mutations
  class DossierModifierAnnotationPieceJustificative < Mutations::DossierModifierAnnotation
    description "Modifier l’annotation au format piece justificative en donnant le signed_id retournée par CreateDirectUpload."

    argument :attachment, ID, required: true

    def resolve(dossier:, annotation_id:, instructeur:, attachment:)
      resolve_with_type(dossier: dossier, annotation_id: annotation_id, instructeur: instructeur, value: attachment) do |annotation, attachment|
        annotation.piece_justificative_file.attach(attachment)
      end
    end

    def ready?(attachment: nil, **args)
      if attachment.present?
        validate_blob(attachment)
      else
        true
      end
    end

    def input_type
      :piece_justificative
    end
  end
end
