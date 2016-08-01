class GestionnaireCanFollowDossier < ActiveRecord::Migration
  def change
    create_table :follows do |t|
      t.belongs_to :gestionnaire, index: true
      t.belongs_to :dossier, index: true
    end
  end
end
