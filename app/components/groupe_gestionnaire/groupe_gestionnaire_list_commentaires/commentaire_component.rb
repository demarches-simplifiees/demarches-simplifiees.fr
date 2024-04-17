class GroupeGestionnaire::GroupeGestionnaireListCommentaires::CommentaireComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(groupe_gestionnaire:, commentaire:)
    @groupe_gestionnaire = groupe_gestionnaire
    @commentaire = commentaire
  end

  def email
    if @commentaire.sender == current_gestionnaire
      "#{current_gestionnaire.email} (C’est vous !)"
    else
      @commentaire.sender_email
    end
  end

  def created_at
    try_format_datetime(@commentaire.created_at)
  end

  def see_button
    link_to 'Voir',
      gestionnaire_groupe_gestionnaire_commentaire_path(@groupe_gestionnaire, @commentaire),
      class: 'button'
  end

  def highlight?
    commentaire_seen_at = current_gestionnaire.commentaire_seen_at(@groupe_gestionnaire, @commentaire.sender_id, @commentaire.sender_type)
    commentaire_seen_at.nil? || commentaire_seen_at < @commentaire.created_at
  end
end
