module CommentaireHelper
  def commentaire_is_from_me_class(commentaire, connected_user)
    if commentaire.email == connected_user.email
      "from-me"
    end
  end

  def commentaire_is_from_guest(commentaire)
    commentaire.dossier.invites.map(&:email).include?(commentaire.email)
  end

  def commentaire_date(commentaire)
    is_current_year = (commentaire.created_at.year == Date.current.year)
    template = is_current_year ? :message_date : :message_date_with_year
    I18n.l(commentaire.created_at.localtime, format: template)
  end
end
