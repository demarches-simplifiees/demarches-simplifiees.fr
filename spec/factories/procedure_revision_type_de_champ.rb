# frozen_string_literal: true

FactoryBot.define do
  factory :procedure_revision_type_de_champ do
    transient do
      from_original { nil }
    end

    after(:build) do |revision_type_de_champ, evaluator|
      if evaluator.from_original
        original = evaluator.from_original

        revision_type_de_champ.type_de_champ = original.type_de_champ
        revision_type_de_champ.position      = original.position
      end
    end
  end
end
