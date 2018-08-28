class MakeFeedbacksRatingNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :feedbacks, :rating, false
  end
end
