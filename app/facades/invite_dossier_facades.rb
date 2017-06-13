class InviteDossierFacades < DossierFacades
  #TODO rechercher en fonction de la personne/email
  def initialize id, email
    @dossier = Invite.where(email: email, id: id).first!.dossier
  end
end
