# frozen_string_literal: true

class CreateGroupeGestionnaires < ActiveRecord::Migration[7.0]
  def change
    create_table "groupe_gestionnaires" do |t|
      t.string :name, null: false
      t.references :groupe_gestionnaire
      t.index [:name], name: :index_groupe_gestionnaires_on_name
      t.timestamps
    end

    create_join_table :groupe_gestionnaires, :gestionnaires do |t|
      t.index [:groupe_gestionnaire_id, :gestionnaire_id], name: :index_on_groupe_gestionnaire_and_gestionnaire
      t.index [:gestionnaire_id, :groupe_gestionnaire_id], name: :index_on_gestionnaire_and_groupe_gestionnaire
    end
  end
end
