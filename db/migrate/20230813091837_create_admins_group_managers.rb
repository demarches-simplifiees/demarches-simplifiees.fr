class CreateAdminsGroupManagers < ActiveRecord::Migration[7.0]
  def change
    create_table "admins_group_managers" do |t|
      t.bigint :user_id, null: false
      t.index [:user_id], name: :index_admins_group_managers_on_user_id
      t.timestamps
    end
  end
end
