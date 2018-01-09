class EnableUnaccentPostgresqlExtension < ActiveRecord::Migration[5.0]
  def up
    execute 'CREATE EXTENSION unaccent;'
  end

  def down
    execute 'DROP EXTENSION unaccent;'
  end
end
