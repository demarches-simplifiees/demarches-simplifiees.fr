class PurgeDraftDossier < ActiveRecord::Migration
  class Dossier < ApplicationRecord
    BROUILLON = ['draft']

    def brouillon?
      BROUILLON.include?(state)
    end
  end

  class Commentaire < ApplicationRecord
    belongs_to :dossier
  end

  class Cerfa < ApplicationRecord
    belongs_to :dossier
    belongs_to :user
  end

  def change
    Cerfa.all.each { |cerfa| cerfa.delete if cerfa.dossier.brouillon? }
    Commentaire.all.each { |com| com.delete if com.dossier.brouillon? }

    Dossier.where(state: :draft).destroy_all
  end
end
