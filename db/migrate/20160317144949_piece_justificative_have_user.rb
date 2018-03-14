class PieceJustificativeHaveUser < ActiveRecord::Migration[5.2]
  class PieceJustificative < ApplicationRecord
    belongs_to :dossier
  end

  class Dossier < ApplicationRecord
    belongs_to :user
  end

  class User < ApplicationRecord
  end

  def change
    add_reference :pieces_justificatives, :user, references: :users

    PieceJustificative.all.each do |piece_justificative|
      piece_justificative.user_id = piece_justificative.dossier.user.id
      piece_justificative.save
    end
  end
end
