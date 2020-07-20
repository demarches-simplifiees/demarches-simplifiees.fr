FactoryBot.define do
  factory :attestation do
    title { 'title' }
    association :dossier
  end

  trait :with_pdf do
    pdf { Rack::Test::UploadedFile.new('spec/fixtures/files/dossierPDF.pdf', 'application/pdf') }
  end
end
