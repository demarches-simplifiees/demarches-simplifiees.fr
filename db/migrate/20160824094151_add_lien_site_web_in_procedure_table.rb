class AddLienSiteWebInProcedureTable < ActiveRecord::Migration
  def change
    add_column :procedures, :lien_site_web, :string
  end
end
