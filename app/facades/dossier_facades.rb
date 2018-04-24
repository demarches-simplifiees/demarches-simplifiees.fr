class DossierFacades
  # TODO rechercher en fonction de la personne/email
  def initialize(dossier_id, email, champ_id = nil)
    @dossier = Dossier.find(dossier_id)
    @champ_id = champ_id
  end

  def dossier
    @dossier.decorate
  end

  def champs
    @dossier.ordered_champs
  end

  def etablissement
    @dossier.etablissement
  end

  def pieces_justificatives
    @dossier.ordered_pieces_justificatives
  end

  def types_de_pieces_justificatives
    @dossier.types_de_piece_justificative.order('order_place ASC')
  end

  def champ_id
    @champ_id
  end

  def commentaires
    @dossier.commentaires.where(champ_id: @champ_id).decorate
  end

  def procedure
    @dossier.procedure
  end

  def invites
    @dossier.invites
  end

  def champs_private
    @dossier.ordered_champs_private
  end

  def individual
    @dossier.individual
  end

  def commentaires_files
    PieceJustificative.where(dossier_id: @dossier.id, type_de_piece_justificative_id: nil)
  end

  def followers
    Gestionnaire.joins(:follows).where("follows.dossier_id=#{@dossier.id}")
  end
end
