class Gestionnaire < ApplicationRecord
  include UserFindByConcern
  has_and_belongs_to_many :groupe_gestionnaires
  has_many :commentaire_groupe_gestionnaires
  has_many :follow_commentaire_groupe_gestionnaires

  belongs_to :user

  delegate :email, to: :user

  default_scope { eager_load(:user) }

  def email
    user&.email
  end

  def active?
    user&.active?
  end

  def can_be_deleted?
    groupe_gestionnaires.roots.each do |rt|
      return false unless rt.gestionnaires.size > 1
    end
    true
  end

  def registration_state
    if user.active?
      'Actif'
    elsif user.reset_password_period_valid?
      'En attente'
    else
      'Expiré'
    end
  end

  def unread_commentaires?(groupe_gestionnaire)
    CommentaireGroupeGestionnaire
      .joins(:groupe_gestionnaire)
      .joins("LEFT JOIN follow_commentaire_groupe_gestionnaires ON follow_commentaire_groupe_gestionnaires.groupe_gestionnaire_id = commentaire_groupe_gestionnaires.groupe_gestionnaire_id AND follow_commentaire_groupe_gestionnaires.sender_id = commentaire_groupe_gestionnaires.sender_id AND follow_commentaire_groupe_gestionnaires.sender_type = commentaire_groupe_gestionnaires.sender_type AND follow_commentaire_groupe_gestionnaires.gestionnaire_id = #{self.id}")
      .where(groupe_gestionnaire: groupe_gestionnaire)
      .where('follow_commentaire_groupe_gestionnaires.commentaire_seen_at IS NULL OR follow_commentaire_groupe_gestionnaires.commentaire_seen_at < commentaire_groupe_gestionnaires.created_at')
      .exists?
  end

  def commentaire_seen_at(groupe_gestionnaire, sender_id, sender_type)
    FollowCommentaireGroupeGestionnaire
      .where(gestionnaire: self, groupe_gestionnaire:, sender_id:, sender_type:)
      .order(id: :desc)
      .last
      &.commentaire_seen_at
  end

  def mark_commentaire_as_seen(groupe_gestionnaire, sender_id, sender_type)
    FollowCommentaireGroupeGestionnaire
      .where(gestionnaire: self, groupe_gestionnaire:, sender_id:, sender_type:, unfollowed_at: nil)
      .first_or_initialize.update(commentaire_seen_at: Time.zone.now)
  end
end
