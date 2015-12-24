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
    @dossier.entreprise.decorate
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
end