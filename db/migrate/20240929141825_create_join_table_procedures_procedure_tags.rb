# frozen_string_literal: true

class CreateJoinTableProceduresProcedureTags < ActiveRecord::Migration[7.0]
  def change
    create_join_table :procedures, :procedure_tags do |t|
      t.index [:procedure_id, :procedure_tag_id], name: 'index_procedures_tags_on_procedure_id_and_tag_id'
      t.index [:procedure_tag_id, :procedure_id], name: 'index_procedures_tags_on_tag_id_and_procedure_id'
    end
  end
end
