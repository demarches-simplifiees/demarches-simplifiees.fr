class AddWhitelistedAtColumnToProcedure < ActiveRecord::Migration[5.0]
  def change
    add_column :procedures, :whitelisted_at, :datetime
  end
end
