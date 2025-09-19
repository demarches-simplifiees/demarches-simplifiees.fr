# frozen_string_literal: true

FactoryBot.define do
  factory :attestation_template do
    title { 'title' }
    body { 'body' }
    json_body { nil }
    footer { 'footer' }
    activated { true }
    version { 1 }
    official_layout { true }
    label_direction { nil }
    label_logo { nil }
    kind { 'acceptation' }
    association :procedure
  end

  trait :v2 do
    version { 2 }
    body { nil }
    title { nil }
    label_logo { "Ministère des devs" }

    json_body do
      {
        "type" => "doc",
        "content" => [
          {
            "type" => "header", "content" => [
              { "type" => "headerColumn", "attrs" => { "textAlign" => "left" }, "content" => [{ "type" => "paragraph", "attrs" => { "textAlign" => "left" } }] },
              { "type" => "headerColumn", "attrs" => { "textAlign" => "left" }, "content" => [{ "type" => "paragraph", "attrs" => { "textAlign" => "left" } }] }
            ]
          },
          { "type" => "title", "attrs" => { "textAlign" => "center" }, "content" => [{ "text" => "Mon titre pour ", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_procedure_libelle", "label" => "libellé démarche" } }] },
          { "type" => "paragraph", "attrs" => { "textAlign" => "left" }, "content" => [{ "text" => "Dossier: n° ", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] },
          {
            "type" => "paragraph",
            "content" => [
              { "text" => "Nom: ", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "individual_last_name", "label" => "prénom" } }, { "text" => " ", "type" => "text" },
              { "type" => "mention", "attrs" => { "id" => "individual_first_name", "label" => "nom" } }, { "text" => " ", "type" => "text" }
            ]
          }
        ]
      }
    end
  end

  trait :with_files do
    logo { Rack::Test::UploadedFile.new('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
    signature { Rack::Test::UploadedFile.new('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
  end

  trait :with_gif_files do
    logo { Rack::Test::UploadedFile.new('./spec/fixtures/files/french-flag.gif', 'image/gif') }
    signature { Rack::Test::UploadedFile.new('./spec/fixtures/files/beta-gouv.gif', 'image/gif') }
  end
end
