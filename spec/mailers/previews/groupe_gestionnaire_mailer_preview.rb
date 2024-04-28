# frozen_string_literal: true

class GroupeGestionnaireMailerPreview < ActionMailer::Preview
  def notify_removed_gestionnaire
    groupe_gestionnaire = GroupeGestionnaire.new(name: 'un groupe gestionnaire')
    current_super_admin_email = 'admin@dgfip.com'
    gestionnaire = Gestionnaire.new(user: user)
    GroupeGestionnaireMailer.notify_removed_gestionnaire(groupe_gestionnaire, gestionnaire.email, current_super_admin_email)
  end

  def notify_added_gestionnaires
    groupe_gestionnaire = GroupeGestionnaire.new(name: 'un groupe gestionnaire')
    current_super_admin_email = 'admin@dgfip.com'
    gestionnaires = [Gestionnaire.new(user: user)]
    GroupeGestionnaireMailer.notify_added_gestionnaires(groupe_gestionnaire, gestionnaires, current_super_admin_email)
  end

  def notify_removed_administrateur
    groupe_gestionnaire = GroupeGestionnaire.new(name: 'un groupe gestionnaire')
    current_super_admin_email = 'admin@dgfip.com'
    administrateur = Administrateur.new(user: user)
    GroupeGestionnaireMailer.notify_removed_administrateur(groupe_gestionnaire, administrateur.email, current_super_admin_email)
  end

  def notify_added_administrateurs
    groupe_gestionnaire = GroupeGestionnaire.new(name: 'un groupe gestionnaire')
    current_super_admin_email = 'admin@dgfip.com'
    administrateurs = [Administrateur.new(user: user)]
    GroupeGestionnaireMailer.notify_added_administrateurs(groupe_gestionnaire, administrateurs, current_super_admin_email)
  end

  def notify_new_commentaire_groupe_gestionnaire
    groupe_gestionnaire = GroupeGestionnaire.new(id: 1, name: 'un groupe gestionnaire')
    commentaire = CommentaireGroupeGestionnaire.new(id: 1)
    admin_email = 'admin@dgfip.com'
    gestionnaire = Gestionnaire.new(user: user)
    commentaire_url = Rails.application.routes.url_helpers.gestionnaire_groupe_gestionnaire_commentaire_url(groupe_gestionnaire, commentaire)
    GroupeGestionnaireMailer.notify_new_commentaire_groupe_gestionnaire(groupe_gestionnaire, commentaire, admin_email, gestionnaire.email, commentaire_url)
  end

  private

  def user
    User.new(id: 10, email: 'test@exemple.fr')
  end
end
