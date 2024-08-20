class RenameSupprimesRecemmentFromProcedurePresentation < ActiveRecord::Migration[7.0]
  def up
    ProcedurePresentation.update_all(%Q(filters = filters || '{"supprimes": []}'))
    change_column_default :procedure_presentations, :filters, { "tous" => [], "suivis" => [], "traites" => [], "a-suivre" => [], "archives" => [], "supprimes" => [], "expirant": [] }
  end

  def down
    change_column_default :procedure_presentations, :filters, { "tous" => [], "suivis" => [], "traites" => [], "a-suivre" => [], "archives" => [], "supprimes_recemment" => [], "expirant": [] }
  end
end
