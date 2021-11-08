class AddStartDayAndEndDayToArchives < ActiveRecord::Migration[6.1]
  def change
    add_column :archives, :start_day, :date
    add_column :archives, :end_day, :date
  end
end
