class AddLienSiteWebInProcedureTable < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :lien_site_web, :string
  end
end
