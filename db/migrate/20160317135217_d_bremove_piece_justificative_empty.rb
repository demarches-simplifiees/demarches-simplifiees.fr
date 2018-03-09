class DBremovePieceJustificativeEmpty < ActiveRecord::Migration
  class PieceJustificative < ApplicationRecord
  end

  def change
    PieceJustificative.where(content: nil).delete_all
  end
end
