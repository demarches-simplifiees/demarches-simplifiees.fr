class AddLienNoticeInProcedureTable < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :lien_notice, :string
  end
end
