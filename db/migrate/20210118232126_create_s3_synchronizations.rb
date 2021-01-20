class CreateS3Synchronizations < ActiveRecord::Migration[6.0]
  def change
    create_table :s3_synchronizations do |t|
      t.boolean :checked

      t.timestamps
    end
  end
end
