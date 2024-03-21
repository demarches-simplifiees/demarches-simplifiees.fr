class Dossiers::MessageComponent < ApplicationComponent
  def initialize(commentaire:, connected_user:, messagerie_seen_at: nil, show_reply_button: false)
    @commentaire = commentaire
    @connected_user = connected_user
    @messagerie_seen_at = messagerie_seen_at
    @show_reply_button = show_reply_button
  end

  attr_reader :commentaire, :connected_user, :messagerie_seen_at

  def correction_badge
    return if commentaire.dossier_correction.nil?
    return helpers.correction_resolved_badge if commentaire.dossier_correction.resolved?

    helpers.pending_correction_badge(connected_user.is_a?(Instructeur) ? :for_instructeur : :for_user)
  end

  private

  def soft_deletable?
    commentaire.soft_deletable?(connected_user)
  end

  def show_reply_button?
    @show_reply_button
  end

  def delete_button_text
    if commentaire.dossier_correction&.pending?
      t('.delete_with_correction_button')
    else
      t('.delete_button')
    end
  end

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

  def icon
    if commentaire.sent_by_system?
      dsfr_icon('fr-icon-message-2-fill', :sm, :mr)
    elsif commentaire.sent_by?(connected_user)
      dsfr_icon('fr-icon-user-fill', :sm, :mr)
    else
      dsfr_icon('fr-icon-discuss-fill', :sm, :mr)
    end
  end

  def commentaire_issuer
    if commentaire.sent_by_system?
      t('.automatic_email')
    elsif commentaire.sent_by?(connected_user)
      t('.you')
    else
      commentaire.redacted_email
    end
  end

  def commentaire_from_guest?
    commentaire.dossier.invites.map(&:email).include?(commentaire.email)
  end

  def commentaire_date
    is_current_year = (commentaire.created_at.year == Time.zone.today.year)
    l(commentaire.created_at, format: is_current_year ? :message_date : :message_date_with_year)
  end

  def highlight?
    commentaire.persisted? && @messagerie_seen_at&.<(commentaire.created_at)
  end
end
