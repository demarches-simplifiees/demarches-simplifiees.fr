class PieceJustificativeHaveUser < ActiveRecord::Migration
  class PieceJustificative < ActiveRecord::Base
    belongs_to :dossier
  end

  class Dossier < ActiveRecord::Base
    belongs_to :user
  end

  class User < ActiveRecord::Base
  end

  def change
    add_reference :pieces_justificatives, :user, references: :users

    PieceJustificative.all.each do |piece_justificative|
      piece_justificative.user_id = piece_justificative.dossier.user.id
      piece_justificative.save
    end
  end
end
