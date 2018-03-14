class ChangeDateCreationTypeToEntreprise < ActiveRecord::Migration[5.2]
  def up
    change_column :entreprises, :date_creation, "timestamp USING to_timestamp(date_creation) at time zone 'UTC-2'"
  end

  def down
    change_column :entreprises, :date_creation, "integer USING extract(epoch from date_creation::timestamp with time zone)::integer"
  end
end
