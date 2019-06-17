class CreateBillSignature < ActiveRecord::Migration[5.2]
  def change
    create_table :bill_signatures do |t|
      t.string :digest
      t.timestamps
    end

    add_reference :dossier_operation_logs, :bill_signature, foreign_key: true
  end
end
