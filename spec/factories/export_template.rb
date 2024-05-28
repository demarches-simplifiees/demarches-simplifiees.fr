FactoryBot.define do
  factory :export_template do
    name { "Mon export" }
    groupe_instructeur
    content {
  {
    "pdf_name" =>
   {
     "type" => "doc",
    "content" => [
      { "type" => "paragraph", "content" => [{ "text" => "export_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_id", "label" => "id dossier" } }, { "text" => " .pdf", "type" => "text" }] }
    ]
   },
   "default_dossier_directory" => {
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
  end
end
