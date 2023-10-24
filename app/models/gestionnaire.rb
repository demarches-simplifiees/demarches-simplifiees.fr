class Gestionnaire < ApplicationRecord
  include UserFindByConcern
  has_and_belongs_to_many :groupe_gestionnaires
  has_many :commentaire_groupe_gestionnaires

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
end
