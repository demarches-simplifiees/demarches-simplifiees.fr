class ChangeEmptytoNilInPreferenceListDossierTable < ActiveRecord::Migration[5.2]
  class PreferenceListDossier < ApplicationRecord
  end

  def change
    PreferenceListDossier.where(table: '').update_all table: nil
  end
end
