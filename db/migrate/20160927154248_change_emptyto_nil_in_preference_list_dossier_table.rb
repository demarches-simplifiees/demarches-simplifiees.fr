class ChangeEmptytoNilInPreferenceListDossierTable < ActiveRecord::Migration
  class PreferenceListDossier < ActiveRecord::Base
  end

  def change
    PreferenceListDossier.where(table: '').update_all table: nil
  end
end
