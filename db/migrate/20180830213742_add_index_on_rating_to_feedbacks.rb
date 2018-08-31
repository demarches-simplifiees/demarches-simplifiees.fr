class AddIndexOnRatingToFeedbacks < ActiveRecord::Migration[5.2]
  def change
    add_index :feedbacks, :rating
  end
end
