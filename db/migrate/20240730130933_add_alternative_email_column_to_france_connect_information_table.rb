# frozen_string_literal: true

class AddAlternativeEmailColumnToFranceConnectInformationTable < ActiveRecord::Migration[7.0]
  def change
    add_column :france_connect_informations, :requested_email, :string
  end
end
