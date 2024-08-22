# frozen_string_literal: true

module MessagerieHelper
  def show_reply_button(commentaire, connected_user)
    commentaire.dossier.present? &&
      commentaire.dossier.messagerie_available? &&
      commentaire.dossier.user == connected_user &&
      !commentaire.sent_by?(connected_user) &&
      commentaire.dossier.commentaires.last == commentaire
  end
end
