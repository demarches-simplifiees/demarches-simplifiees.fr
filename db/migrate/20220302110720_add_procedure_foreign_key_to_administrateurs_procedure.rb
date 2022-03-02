class AddProcedureForeignKeyToAdministrateursProcedure < ActiveRecord::Migration[6.1]
  def up
    say_with_time 'Removing AdministrateursProcedures where the associated Procedure no longer exists ' do
      # Find procedure_ids in AdministrateursProcedure that don't have an existing Procedure attached
      deleted_procedure_ids = query_values <<~SQL1
        SELECT administrateurs_procedures.procedure_id
        FROM administrateurs_procedures
        LEFT OUTER JOIN procedures on procedures.id = administrateurs_procedures.procedure_id
        WHERE procedures.id IS NULL
      SQL1

      # Delete the AdministrateursProcedure having those procedure_ids
      exec_delete <<~SQL2
        DELETE FROM administrateurs_procedures
        WHERE administrateurs_procedures.procedure_id IN (#{deleted_procedure_ids.uniq.join(', ')})
      SQL2
    end

    add_foreign_key :administrateurs_procedures, :procedures
  end

  def down
    remove_foreign_key :administrateurs_procedures, :procedures
  end
end
