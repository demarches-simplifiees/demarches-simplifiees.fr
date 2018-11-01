class Account < ApplicationRecord
  belongs_to :usager, class_name: 'User'
  belongs_to :instructeur, class_name: 'Gestionnaire'
  belongs_to :administrateur

  attr_accessor :manager

  def id
    usager&.id || instructeur&.id || administrateur&.id
  end

  def email
    usager&.email || instructeur&.email || administrateur&.email
  end

  def role_names
    roles = [usager, instructeur, administrateur, manager]
      .compact.map(&:role_name)

    if roles.empty?
      roles << 'Visiteur'
    end

    roles.join(', ')
  end

  def signed_in?
    usager? || instructeur? || administrateur?
  end

  def usager?
    usager.present?
  end

  def instructeur?
    instructeur.present?
  end

  def administrateur?
    administrateur.present?
  end

  def manager?
    manager.present?
  end
end
