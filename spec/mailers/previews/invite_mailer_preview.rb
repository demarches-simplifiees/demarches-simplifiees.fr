class InviteMailerPreview < ActionMailer::Preview
  def invite_user
    InviteMailer.invite_user(invite)
  end

  def invite_guest
    InviteMailer.invite_guest(invite)
  end

  private

  def invite
    Invite.new(
      id: 10,
      dossier: dossier,
      user: invited_user,
      email: invited_user.email,
      email_sender: 'sender@gouv.fr'
    )
  end

  def dossier
    Dossier.new(procedure: procedure)
  end

  def procedure
    Procedure.new(libelle: 'Permis de construire en zone inondable')
  end

  def invited_user
    User.new(email: 'Invité@gouv.fr')
  end
end
