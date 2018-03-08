class DeleteValueOfFilterProcedure < ActiveRecord::Migration[5.2]
  class Gestionnaire < ApplicationRecord
  end

  def change
    Gestionnaire.all.update_all(procedure_filter: '{}')
  end
end
