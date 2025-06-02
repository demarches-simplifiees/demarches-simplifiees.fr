# frozen_string_literal: true

class AddEmailMergeTokenColumnToFranceConnectInformation < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :france_connect_informations, :email_merge_token, :string
    add_column :france_connect_informations, :email_merge_token_created_at, :datetime

    add_index :france_connect_informations, :email_merge_token, algorithm: :concurrently
  end
end
