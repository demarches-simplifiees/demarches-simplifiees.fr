# frozen_string_literal: true

class RemoveInstructeurReferencesFromProConnectInformation < ActiveRecord::Migration[7.0]
  def up
    remove_index :agent_connect_informations, :instructeur_id if index_exists?(:agent_connect_informations, :instructeur_id)

    remove_foreign_key :agent_connect_informations, :instructeurs if foreign_key_exists?(:agent_connect_informations, :instructeurs)

    safety_assured { remove_column :agent_connect_informations, :instructeur_id }
  end

  def down
    add_column :agent_connect_informations, :instructeur_id, :bigint
    add_index :agent_connect_informations, :instructeur_id
    add_foreign_key :agent_connect_informations, :instructeurs
  end
end
