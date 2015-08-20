class PieceJointe < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_piece_jointe
  delegate :api_entreprise, :libelle, to: :type_piece_jointe
  alias_attribute :type, :type_piece_jointe_id
  mount_uploader :content, PieceJointeUploader


  def empty?
    content.blank?
  end
end
