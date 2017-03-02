class ChangeDateCreationTypeToEntreprise < ActiveRecord::Migration
  def up
    if Rails.env.test?
      change_column :entreprises, :date_creation, "timestamp"
    else
      change_column :entreprises, :date_creation, "timestamp USING to_timestamp(date_creation) at time zone 'UTC-2'"
    end
  end

  def down
    change_column :entreprises, :date_creation, "integer USING extract(epoch from date_creation::timestamp with time zone)::integer"
  end
end
