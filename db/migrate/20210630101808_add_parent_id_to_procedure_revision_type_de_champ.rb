# frozen_string_literal: true

class AddParentIdToProcedureRevisionTypeDeChamp < ActiveRecord::Migration[6.1]
  def change
    add_belongs_to :procedure_revision_types_de_champ, :parent, index: true, foreign_key: { to_table: :procedure_revision_types_de_champ }
  end
end
