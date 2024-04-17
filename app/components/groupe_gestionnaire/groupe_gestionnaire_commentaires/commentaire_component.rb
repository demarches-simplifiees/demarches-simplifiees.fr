class GroupeGestionnaire::GroupeGestionnaireCommentaires::CommentaireComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(commentaire:, connected_user:, commentaire_seen_at: nil, is_gestionnaire: true)
    @commentaire = commentaire
    @connected_user = connected_user
    @is_gestionnaire = is_gestionnaire
    @groupe_gestionnaire = commentaire.groupe_gestionnaire
    @commentaire_seen_at = commentaire_seen_at
  end

  private

  def highlight_if_unseen_class
    if highlight?
      'highlighted'
    end
  end

  def scroll_to_target
    if highlight?
      { scroll_to_target: 'to' }
    end
  end

  def commentaire_issuer
    if @commentaire.sent_by?(@connected_user)
      t('.you')
    else
      @commentaire.gestionnaire_id ? @commentaire.gestionnaire_email : @commentaire.sender_email
    end
  end

  def commentaire_date
    is_current_year = (@commentaire.created_at.year == Time.zone.today.year)
    l(@commentaire.created_at, format: is_current_year ? :message_date : :message_date_with_year)
  end

  def highlight?
    @commentaire.persisted? && (@commentaire_seen_at.nil? || @commentaire_seen_at < @commentaire.created_at)
  end
end
