class UpdateKeyArchivesIndex < ActiveRecord::Migration[6.1]
  def up
    remove_index :archives, [:key, :time_span_type, :month], unique: true
    add_index :archives, [:key, :time_span_type, :month, :start_day, :end_day], unique: true, name: 'index_archives_on_key_and_period'
  end

  def down
    remove_index :archives, [:key, :time_span_type, :month, :start_day, :end_day], unique: true, name: 'index_archives_on_key_and_period'
    add_index :archives, [:key, :time_span_type, :month], unique: true
  end
end
