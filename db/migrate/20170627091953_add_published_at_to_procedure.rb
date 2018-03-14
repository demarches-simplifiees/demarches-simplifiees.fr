class AddPublishedAtToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :published_at, :datetime
  end
end
