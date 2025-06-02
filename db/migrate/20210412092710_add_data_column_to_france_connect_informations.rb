# frozen_string_literal: true

class AddDataColumnToFranceConnectInformations < ActiveRecord::Migration[6.1]
  def change
    add_column :france_connect_informations, :data, :jsonb
  end
end
