class AddEmailToFranceConnectInformation < ActiveRecord::Migration
  def change
    add_column :france_connect_informations, :email_france_connect, :string
  end
end
