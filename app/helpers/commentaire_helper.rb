module CommentaireHelper
  def commentaire_is_from_me_class(commentaire, email)
    if commentaire.email == email
      "from-me"
    end
  end
end
