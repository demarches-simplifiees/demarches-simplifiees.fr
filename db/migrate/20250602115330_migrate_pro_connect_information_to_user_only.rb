# frozen_string_literal: true

class MigrateProConnectInformationToUserOnly < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    change_column_null :agent_connect_informations, :instructeur_id, true
    add_index :agent_connect_informations, [:user_id, :sub],
              unique: true,
              name: 'index_agent_connect_informations_on_user_id_and_sub',
              algorithm: :concurrently
    remove_foreign_key :agent_connect_informations, :instructeurs
  end

  def down
    add_foreign_key :agent_connect_informations, :instructeurs
    remove_index :agent_connect_informations,
                 name: 'index_agent_connect_informations_on_user_id_and_sub',
                 algorithm: :concurrently
    change_column_null :agent_connect_informations, :instructeur_id, false
  end
end
