# frozen_string_literal: true

class Dossiers::MessageComponentPreview < ViewComponent::Preview
  def with_default_commentaire
    render Dossiers::MessageComponent.new(commentaire: commentaire, connected_user: user)
  end

  def with_discarded_commentaire
    render Dossiers::MessageComponent.new(commentaire: discarded_commentaire, connected_user: user)
  end

  private

  def user
    User.new email: "usager@example.com", locale: I18n.locale
  end

  def commentaire
    Commentaire.new body: 'Hello world!', email: user.email, dossier: dossier, created_at: 2.days.ago
  end

  def discarded_commentaire
    Commentaire.new body: 'Hello world!', email: user.email, dossier: dossier, created_at: 2.days.ago, discarded_at: 1.day.ago
  end

  def dossier
    Dossier.new(id: 47882, state: :en_instruction, procedure: procedure, user: user)
  end

  def procedure
    Procedure.new id: 1234, libelle: 'Dotation d’Équipement des Territoires Ruraux - Exercice 2019'
  end
end
