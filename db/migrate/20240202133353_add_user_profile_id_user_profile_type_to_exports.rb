class AddUserProfileIdUserProfileTypeToExports < ActiveRecord::Migration[7.0]
  def change
    add_column :exports, :user_profile_id, :bigint
    add_column :exports, :user_profile_type, :string
  end
end
