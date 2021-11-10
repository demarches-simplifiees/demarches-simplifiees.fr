class AddAPIParticulierSourcesToProcedure < ActiveRecord::Migration[6.0]
  def change
    add_column :procedures, :api_particulier_sources, :jsonb, :default => {}
    add_index  :procedures, :api_particulier_sources, using: :gin
  end
end
