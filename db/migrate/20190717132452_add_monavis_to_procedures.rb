class AddMonavisToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :monavis_embed, :text
  end
end
