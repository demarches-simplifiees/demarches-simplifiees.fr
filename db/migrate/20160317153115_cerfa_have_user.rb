class CerfaHaveUser < ActiveRecord::Migration
  class Cerfa < ActiveRecord::Base
    belongs_to :dossier
  end

  class Dossier < ActiveRecord::Base
    belongs_to :user
  end

  class User < ActiveRecord::Base
  end

  def change
    add_reference :cerfas, :user, references: :users

    Cerfa.all.each do |cerfa|
      cerfa.user_id = cerfa.dossier.user.id
      cerfa.save
    end
  end
end
