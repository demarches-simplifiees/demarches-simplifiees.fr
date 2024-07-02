FactoryBot.define do
  factory :export_template do
    name { "Mon export" }
    groupe_instructeur
    content {
  {
    "export_pdf" => {
      "template" => {
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph",
            "content" => [
              { "text" => "export_", "type" => "text" },
              { "type" => "mention", "attrs" => { "id" => "dossier_id", "label" => "id dossier" } },
              { "text" => " .pdf", "type" => "text" }
            ]
          }
        ]
      }
    },
   "dossier_folder" => {
     "template" => {
       "type" => "doc",
       "content" =>
       [
         {
           "type" => "paragraph",
           "content" =>
           [
             { "text" => "dossier_", "type" => "text" },
             { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } },
             { "text" => " ", "type" => "text" }
           ]
         }
       ]
     }
   },
   "pjs" => []
  }
}
    kind { "zip" }

    to_create do |export_template, _context|
      export_template.set_default_values
      export_template.save
    end

    trait :with_custom_content do
      to_create do |export_template, context|
        export_template.set_default_values
        export_template.content = context.content
        export_template.save
      end
    end

    trait :with_custom_ddd_prefix do
      transient do
        ddd_prefix { 'dossier_' }
      end

      to_create do |export_template, context|
        export_template.set_default_values
        export_template.content["dossier_folder"]["template"]["content"] = [
          {
            "type" => "paragraph",
            "content" =>
            [
              { "text" => context.ddd_prefix, "type" => "text" },
              { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } },
              { "text" => " ", "type" => "text" }
            ]
          }
        ]
        export_template.save
      end
    end

    trait :with_date_depot_for_export_pdf do
      to_create do |export_template, _|
        export_template.set_default_values
        export_template.content["export_pdf"]["template"]["content"] = [
          {
            "type" => "paragraph",
            "content" =>
            [
              { "text" => "export_", "type" => "text" },
              { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } },
              { "text" => "-", "type" => "text" },
              { "type" => "mention", "attrs" => { "id" => "dossier_depose_at", "label" => "date de dépôt" } },
              { "text" => " ", "type" => "text" }
            ]
          }
        ]
        export_template.save
      end
    end
  end
end
