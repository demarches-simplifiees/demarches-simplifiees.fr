# frozen_string_literal: true

module CommentaireHelper
  def commentaire_is_from_me_class(commentaire, connected_user)
    if commentaire.sent_by?(connected_user)
      "from-me"
    end
  end

  def commentaire_answer_action(commentaire, connected_user)
    if commentaire.sent_by?(connected_user)
      I18n.t('helpers.commentaire.send_message_to_instructeur')
    else
      I18n.t('helpers.commentaire.reply_in_mailbox')
    end
  end
end
