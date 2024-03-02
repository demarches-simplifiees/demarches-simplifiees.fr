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
 "default_dossier_directory" =>
 {
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
  end
end
