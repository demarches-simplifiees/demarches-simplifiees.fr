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
        original.revision_types_de_champ.each do |r_tdc|
          #revision.revision_types_de_champ << 
          build(:procedure_revision_type_de_champ, from_original: r_tdc)
        end
        original.revision_types_de_champ_private.each do |r_tdc|
          #revision.revision_types_de_champ_private << 
          build(:procedure_revision_type_de_champ, from_original: r_tdc)
        end
        pp "build procedure_revision from original"
      end
    end
  end
end
