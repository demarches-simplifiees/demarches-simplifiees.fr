class InviteDossierFacades < DossierFacades

  #TODO rechercher en fonction de la personne/email
  def initialize dossier_id, email
    @dossier = Invite.where(email: email, dossier_id: dossier_id).first!.dossier
  end
end