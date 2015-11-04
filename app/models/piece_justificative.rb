class PieceJustificative < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_piece_justificative
  delegate :api_entreprise, :libelle, to: :type_de_piece_justificative
  alias_attribute :type, :type_de_piece_justificative_id
  mount_uploader :content, PieceJustificativeUploader

  def empty?
    content.blank?
  end
end
