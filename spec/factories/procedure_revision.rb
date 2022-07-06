FactoryBot.define do
  factory :procedure_revision do
    transient do
      from_original { nil }
    end

    after(:build) do |revision, evaluator|
      if evaluator.from_original
        original = evaluator.from_original

        revision.procedure = original.procedure
        revision.attestation_template_id = original.attestation_template_id
        revision.dossier_submitted_message_id = original.dossier_submitted_message_id
        original.revision_types_de_champ_public.each do |r_tdc|
          revision.revision_types_de_champ_public << build(:procedure_revision_type_de_champ, from_original: r_tdc)
        end
        original.revision_types_de_champ_private.each do |r_tdc|
          revision.revision_types_de_champ_private << build(:procedure_revision_type_de_champ, from_original: r_tdc)
        end
      end
    end
  end
end
