class AddPgExtraExtensions < ActiveRecord::Migration[7.0]
  def up
    RailsPgExtras.add_extensions
  end

  def down
  end
end
