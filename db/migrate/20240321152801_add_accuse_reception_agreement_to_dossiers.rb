class AddAccuseReceptionAgreementToDossiers < ActiveRecord::Migration[7.0]
  def change
    add_column :dossiers, :accuse_reception_agreement_at, :date
  end
end
