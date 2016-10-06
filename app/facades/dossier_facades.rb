class DossierFacades

  #TODO rechercher en fonction de la personne/email
  def initialize dossier_id, email
    @dossier = Dossier.where(archived: false).find(dossier_id)
    @email = email
  end

  def dossier
    @dossier.decorate
  end

  def champs
    @dossier.ordered_champs
  end

  def entreprise
    @dossier.entreprise.decorate unless @dossier.entreprise.nil? || @dossier.entreprise.siren.blank?
  end

  def etablissement
    @dossier.etablissement
  end

  def pieces_justificatives
    @dossier.pieces_justificatives
  end

  def commentaires
    @dossier.ordered_commentaires.all.decorate
  end

  def commentaire_email
    @email
  end

  def procedure
    @dossier.procedure
  end

  def cerfas_ordered
    @dossier.cerfa.order('created_at DESC')
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