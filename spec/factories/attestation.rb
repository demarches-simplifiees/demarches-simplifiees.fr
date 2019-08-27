FactoryBot.define do
  factory :attestation do
    title { 'title' }
    dossier { create(:dossier) }
  end

  trait :with_legacy_pdf do
    pdf { Rack::Test::UploadedFile.new("./spec/fixtures/files/dossierPDF.pdf", 'application/pdf') }
  end
end
