# frozen_string_literal: true

class AddTargetModelIdIndexToTargetedUserLinks < ActiveRecord::Migration[6.1]
  include Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_concurrent_index :targeted_user_links, :target_model_id
  end
end
