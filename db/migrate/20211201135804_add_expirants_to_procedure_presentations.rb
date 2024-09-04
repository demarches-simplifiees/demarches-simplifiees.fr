# frozen_string_literal: true

class AddExpirantsToProcedurePresentations < ActiveRecord::Migration[6.1]
  def up
    ProcedurePresentation.update_all(%Q(filters = filters || '{"expirant": []}'))
    change_column_default :procedure_presentations, :filters, { "tous" => [], "suivis" => [], "traites" => [], "a-suivre" => [], "archives" => [], "expirant": [] }
  end

  def down
    change_column_default :procedure_presentations, :filters, { "tous" => [], "suivis" => [], "traites" => [], "a-suivre" => [], "archives" => [] }
  end
end
