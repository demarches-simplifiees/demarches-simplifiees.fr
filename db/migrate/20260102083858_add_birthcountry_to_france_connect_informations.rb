# frozen_string_literal: true

class AddBirthcountryToFranceConnectInformations < ActiveRecord::Migration[7.2]
  def change
    add_column :france_connect_informations, :birthcountry, :string
  end
end
