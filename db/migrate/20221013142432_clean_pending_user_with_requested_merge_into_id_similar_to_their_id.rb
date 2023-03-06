class CleanPendingUserWithRequestedMergeIntoIdSimilarToTheirId < ActiveRecord::Migration[6.1]
  def change
    User.where('users.id = users.requested_merge_into_id').update_all(requested_merge_into_id: nil)
  end
end
