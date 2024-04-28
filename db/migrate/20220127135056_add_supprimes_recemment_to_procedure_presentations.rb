# frozen_string_literal: true

class AddSupprimesRecemmentToProcedurePresentations < ActiveRecord::Migration[6.1]
  def up
    ProcedurePresentation.update_all(%Q(filters = filters || '{"supprimes_recemment": []}'))
    change_column_default :procedure_presentations, :filters, { "tous" => [], "suivis" => [], "traites" => [], "a-suivre" => [], "archives" => [], "supprimes_recemment" => [], "expirant": [] }
  end

  def down
    change_column_default :procedure_presentations, :filters, { "tous" => [], "suivis" => [], "traites" => [], "a-suivre" => [], "archives" => [], "expirant": [] }
  end
end
