module CommentaireHelper
  def commentaire_is_from_me_class(commentaire, email)
    if commentaire.email == email
      "from-me"
    end
  end

  def commentaire_date(commentaire)
    is_current_year = (commentaire.created_at.year == Date.current.year)
    template = is_current_year ? :message_date : :message_date_with_year
    I18n.l(commentaire.created_at.localtime, format: template)
  end
end
