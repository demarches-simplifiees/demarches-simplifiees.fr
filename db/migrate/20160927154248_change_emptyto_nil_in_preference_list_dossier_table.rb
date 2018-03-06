class ChangeEmptytoNilInPreferenceListDossierTable < ActiveRecord::Migration
  class PreferenceListDossier < ApplicationRecord
  end

  def change
    PreferenceListDossier.where(table: '').update_all table: nil
  end
end
