class CreateProcedurePresentations < ActiveRecord::Migration[5.0]
  def change
    create_table :procedure_presentations do |t|
      t.references :assign_to, index: { unique: true }, foreign_key: true
      t.text :displayed_fields, array: true, default: [{ "label" => "Demandeur", "table" => "user", "column" => "email" }.to_json], null: false
      t.json :sort, default: { "table" => "self", "column" => "id", "order" => "desc" }.to_json, null: false
      t.json :filters, default: { "a-suivre" => [], "suivis" => [], "traites" => [], "tous" => [], "archives" => [] }.to_json, null: false
    end
  end
end
