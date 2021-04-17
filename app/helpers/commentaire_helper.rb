module CommentaireHelper
  def commentaire_is_from_me_class(commentaire, connected_user)
    if commentaire.sent_by?(connected_user)
      "from-me"
    end
  end

  def commentaire_answer_action(commentaire, connected_user)
    if commentaire.sent_by?(connected_user)
      I18n.t('helpers.commentaire_helper.send_message_instructor')
    else
      I18n.t('helpers.commentaire_helper.reply_in_mailbox_button')
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

  def pretty_commentaire(commentaire)
    body_formatted = commentaire.sent_by_system? ? commentaire.body : simple_format(commentaire.body)
    sanitize(body_formatted)
  end
end
