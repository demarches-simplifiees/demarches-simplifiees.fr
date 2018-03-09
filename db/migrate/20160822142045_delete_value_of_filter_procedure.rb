class DeleteValueOfFilterProcedure < ActiveRecord::Migration
  class Gestionnaire < ApplicationRecord
  end

  def change
    Gestionnaire.all.update_all(procedure_filter: '{}')
  end
end
