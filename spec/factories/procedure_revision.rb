# frozen_string_literal: true

FactoryBot.define do
  factory :procedure_revision do
    transient do
      from_original { nil }
    end

    after(:build) do |revision, evaluator|
      if evaluator.from_original
        from_revision = evaluator.from_original

        revision.procedure = from_revision.procedure
        revision.dossier_submitted_message_id = from_revision.dossier_submitted_message_id

        coordinate_map = {}
        revision_types_de_champ = from_revision.revision_types_de_champ.map do |from_coordinate|
          parent = from_coordinate.parent.present? ? coordinate_map[from_coordinate.parent] : nil

          coordinate = build(:procedure_revision_type_de_champ,
            revision: revision,
            type_de_champ: from_coordinate.type_de_champ,
            position: from_coordinate.position,
            parent: parent)

          coordinate_map[from_coordinate] = coordinate
          coordinate
        end

        revision.association(:revision_types_de_champ).target = revision_types_de_champ
      end
    end
  end
end
