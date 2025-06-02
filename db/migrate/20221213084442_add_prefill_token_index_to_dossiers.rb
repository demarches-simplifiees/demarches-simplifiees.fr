# frozen_string_literal: true

class AddPrefillTokenIndexToDossiers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :dossiers, :prefill_token, unique: true, algorithm: :concurrently
  end
end
