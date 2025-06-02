# frozen_string_literal: true

class AddDefautGroupeInstructeurIdToProcedures < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :procedures, :defaut_groupe_instructeur, index: { algorithm: :concurrently }
  end
end
