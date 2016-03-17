class DBremovePieceJustificativeEmpty < ActiveRecord::Migration
  class PieceJustificative < ActiveRecord::Base
  end

  def change
    PieceJustificative.where(content: nil).delete_all
  end
end
