class Commentaire < ActiveRecord::Base
  belongs_to :dossier

  belongs_to :piece_justificative
end
