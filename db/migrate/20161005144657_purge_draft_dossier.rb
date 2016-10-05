class PurgeDraftDossier < ActiveRecord::Migration
  class Dossier < ActiveRecord::Base
    BROUILLON = %w(draft)

    def brouillon?
      BROUILLON.include?(state)
    end
  end

  class Commentaire < ActiveRecord::Base
    belongs_to :dossier
  end

  class Cerfa < ActiveRecord::Base
    belongs_to :dossier
    belongs_to :user
  end

  def change
    Cerfa.all.each { |cerfa| cerfa.delete if cerfa.dossier.brouillon? }
    Commentaire.all.each { |com| com.delete if com.dossier.brouillon? }

    Dossier.where(state: :draft).destroy_all
  end
end
