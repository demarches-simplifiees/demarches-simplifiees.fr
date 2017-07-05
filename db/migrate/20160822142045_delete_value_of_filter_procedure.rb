class DeleteValueOfFilterProcedure < ActiveRecord::Migration
  class Gestionnaire < ActiveRecord::Base
  end

  def change
    Gestionnaire.all.update_all(procedure_filter: '{}')
  end
end
