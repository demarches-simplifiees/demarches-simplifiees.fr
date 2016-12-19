class Commentaire < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :champ

  belongs_to :piece_justificative

  def header
    "#{email}, " + created_at.localtime.strftime('%d %b %Y %H:%M')
  end
end
