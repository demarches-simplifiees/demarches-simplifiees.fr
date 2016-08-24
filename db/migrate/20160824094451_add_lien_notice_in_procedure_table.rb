class AddLienNoticeInProcedureTable < ActiveRecord::Migration
  def change
    add_column :procedures, :lien_notice, :string
  end
end
