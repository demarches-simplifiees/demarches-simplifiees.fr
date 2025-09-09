# frozen_string_literal: true

FactoryBot.define do
  factory :attestation_refus_template do
    title { 'title' }
    body { 'body' }
    footer { 'footer' }
    activated { true }
    state { 'published' }
    version { 1 }
    association :procedure

    trait :with_files do
      after(:build) do |attestation_refus_template, _evaluator|
        attestation_refus_template.logo.attach(
          io: StringIO.new(Rails.root.join("spec/fixtures/files/logo_test_procedure.png").read),
          filename: "logo_test_procedure.png",
          content_type: "image/png"
        )
        attestation_refus_template.signature.attach(
          io: StringIO.new(Rails.root.join("spec/fixtures/files/logo_test_procedure.png").read),
          filename: "signature_test_procedure.png",
          content_type: "image/png"
        )
      end
    end

    trait :v2 do
      version { 2 }
      json_body { AttestationRefusTemplate::TIPTAP_BODY_DEFAULT }
    end
  end
end