class RemoveMarkOnFeedbacks < ActiveRecord::Migration[5.2]
  def change
    remove_column :feedbacks, :mark
  end
end
