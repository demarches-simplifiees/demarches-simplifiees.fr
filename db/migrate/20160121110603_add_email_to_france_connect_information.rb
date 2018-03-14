class AddEmailToFranceConnectInformation < ActiveRecord::Migration[5.2]
  def change
    add_column :france_connect_informations, :email_france_connect, :string
  end
end
