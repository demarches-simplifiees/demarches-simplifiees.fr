class CerfaHaveUser < ActiveRecord::Migration
  class Cerfa < ApplicationRecord
    belongs_to :dossier
  end

  class Dossier < ApplicationRecord
    belongs_to :user
  end

  class User < ApplicationRecord
  end

  def change
    add_reference :cerfas, :user, references: :users

    Cerfa.all.each do |cerfa|
      cerfa.user_id = cerfa.dossier.user.id
      cerfa.save
    end
  end
end
