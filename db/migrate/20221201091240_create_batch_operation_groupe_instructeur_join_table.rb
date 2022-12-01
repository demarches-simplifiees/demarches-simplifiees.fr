class CreateBatchOperationGroupeInstructeurJoinTable < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      create_table "batch_operations_groupe_instructeurs", force: :cascade do |t|
        t.bigint "batch_operation_id", null: false
        t.bigint "groupe_instructeur_id", null: false

        t.timestamps
      end
    end
  end
end
