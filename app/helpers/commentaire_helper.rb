module CommentaireHelper
  def commentaire_is_from_me_class(commentaire, connected_user)
    if commentaire.sent_by?(connected_user)
      "from-me"
    end
  end

  def commentaire_answer_action(commentaire, connected_user)
    if commentaire.sent_by?(connected_user)
      "Envoyer un message à l’instructeur"
    else
      "Répondre dans la messagerie"
    end
  end

  def commentaire_is_from_guest(commentaire)
    commentaire.dossier.invites.map(&:email).include?(commentaire.email)
  end

  def commentaire_date(commentaire)
    is_current_year = (commentaire.created_at.year == Time.zone.today.year)
    template = is_current_year ? :message_date : :message_date_with_year
    I18n.l(commentaire.created_at, format: template)
  end
end
