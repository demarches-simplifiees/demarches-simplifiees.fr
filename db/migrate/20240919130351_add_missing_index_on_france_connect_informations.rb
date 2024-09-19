# frozen_string_literal: true

class AddMissingIndexOnFranceConnectInformations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :france_connect_informations, :france_connect_particulier_id, algorithm: :concurrently, name: 'idx_france_connect_particulier_id'
  end
end
