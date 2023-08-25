class CreateAdminsGroups < ActiveRecord::Migration[7.0]
  def change
    create_table "admins_groups" do |t|
      t.string :name, null: false
      t.references :admins_group
      t.index [:name], name: :index_admins_groups_on_name
      t.timestamps
    end

    create_join_table :admins_groups, :admins_group_managers do |t|
      t.index [:admins_group_id, :admins_group_manager_id], name: :index_on_admins_group_and_admins_group_manager
      t.index [:admins_group_manager_id, :admins_group_id], name: :index_on_admins_group_manager_and_admins_group
    end
  end
end
