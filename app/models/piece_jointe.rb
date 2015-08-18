class PieceJointe < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_piece_jointe
  delegate :api_entreprise, to: :type_piece_jointe
  mount_uploader :content, PieceJointeUploader


  # TODO: remove this function, find another way
  def self.get_array_id_pj_valid_for_dossier(dossier_id)
    @array_id_pj_valides = []
    where(dossier_id: dossier_id).each do |pj_valide|
      @array_id_pj_valides << pj_valide.type_piece_jointe_id
    end

    @array_id_pj_valides
  end
end
