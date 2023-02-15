class Dossiers::MessageComponent < ApplicationComponent
  def initialize(commentaire:, connected_user:, messagerie_seen_at: nil, show_reply_button: false)
    @commentaire = commentaire
    @connected_user = connected_user
    @messagerie_seen_at = messagerie_seen_at
    @show_reply_button = show_reply_button
  end

  attr_reader :commentaire, :connected_user, :messagerie_seen_at

  private

  def show_reply_button?
    @show_reply_button
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

  def icon_path
    if commentaire.sent_by_system?
      'icons/mail.svg'
    elsif commentaire.sent_by?(connected_user)
      'icons/account-circle.svg'
    else
      'icons/blue-person.svg'
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

  def commentaire_body
    if commentaire.discarded?
      t('.deleted_body')
    else
      body_formatted = commentaire.sent_by_system? ? commentaire.body : simple_format(commentaire.body)
      sanitize(body_formatted, commentaire.sent_by_system? ? { scrubber: Sanitizers::MailScrubber.new } : {})
    end
  end

  def highlight?
    commentaire.created_at.present? && @messagerie_seen_at&.<(commentaire.created_at)
  end
end
