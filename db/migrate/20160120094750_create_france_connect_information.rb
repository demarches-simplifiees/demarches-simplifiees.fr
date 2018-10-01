class CreateFranceConnectInformation < ActiveRecord::Migration
  class User < ApplicationRecord
  end

  class FranceConnectInformation < ApplicationRecord
  end

  def up
    create_table :france_connect_informations do |t|
      t.string :gender
      t.string :given_name
      t.string :family_name
      t.date :birthdate
      t.string :birthplace
      t.string :france_connect_particulier_id
    end

    add_reference :france_connect_informations, :user, references: :users

    User.all.each do |user|
      if user.france_connect_particulier_id.present?
        FranceConnectInformation.create({
          gender: user.gender,
          given_name: user.given_name,
          family_name: user.family_name,
          birthdate: user.birthdate,
          birthplace: user.birthplace,
          france_connect_particulier_id: user.france_connect_particulier_id,
          user_id: user.id
        })
      end
    end

    remove_column :users, :gender
    remove_column :users, :given_name
    remove_column :users, :family_name
    remove_column :users, :birthdate
    remove_column :users, :birthplace
    remove_column :users, :france_connect_particulier_id
  end

  def down
    add_column :users, :gender, :string
    add_column :users, :given_name, :string
    add_column :users, :family_name, :string
    add_column :users, :birthdate, :date
    add_column :users, :birthplace, :string
    add_column :users, :france_connect_particulier_id, :string

    FranceConnectInformation.all.each do |fci|
      User.find(fci.user_id).update({
        gender: fci.gender,
        given_name: fci.given_name,
        family_name: fci.family_name,
        birthdate: fci.birthdate,
        birthplace: fci.birthplace,
        france_connect_particulier_id: fci.france_connect_particulier_id
      })
    end

    drop_table :france_connect_informations
  end
end
