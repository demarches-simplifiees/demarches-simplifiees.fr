class CreateTaskRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :task_records, id: false do |t|
      t.string :version, null: false
    end
  end
end
