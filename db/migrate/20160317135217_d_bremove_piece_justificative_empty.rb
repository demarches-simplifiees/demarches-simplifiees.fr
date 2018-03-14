class DBremovePieceJustificativeEmpty < ActiveRecord::Migration[5.2]
  class PieceJustificative < ApplicationRecord
  end

  def change
    PieceJustificative.where(content: nil).delete_all
  end
end
