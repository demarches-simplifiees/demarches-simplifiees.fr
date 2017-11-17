class ChangeProcedurePresentationDefault < ActiveRecord::Migration[5.0]
  def change
    change_column_default :procedure_presentations, :sort, from: { "table" => "self", "column" => "id", "order" => "desc" }.to_json, to: { "table" => "notifications", "column" => "notifications", "order" => "desc" }.to_json
  end
end
