class DossiersListFacades
  include Rails.application.routes.url_helpers

  attr_accessor :procedure, :current_devise_profil, :liste

  def initialize current_devise_profil, liste, procedure = nil
    @current_devise_profil = current_devise_profil
    @liste = liste
    @procedure = procedure
  end

  def service
    if gestionnaire?
      @service ||= DossiersListGestionnaireService.new @current_devise_profil, @liste, @procedure
    elsif user?
      @service ||= DossiersListUserService.new @current_devise_profil, @liste
    end
  end

  def total_dossier
    current_devise_profil.dossiers.where(archived: false).count
  end

  def total_dossier_follow
    @current_devise_profil.dossiers_follow.count
  end

  def total_new_dossier
    current_devise_profil.dossiers.where(state: :initiated, archived: false).count
  end

  def new_dossier_number procedure_id
    current_devise_profil.dossiers.where(state: :initiated, archived: false, procedure_id: procedure_id).count
  end

  def gestionnaire_procedures_name_and_id_list
    @current_devise_profil.procedures.order('libelle ASC').inject([]) { |acc, procedure| acc.push({id: procedure.id, libelle: procedure.libelle, unread_notifications: @current_devise_profil.dossier_with_notification_for(procedure)}) }
  end

  def unread_notifications
    current_devise_profil.notifications
  end

  def dossiers_with_unread_notifications
    (unread_notifications.inject([]) { |acc, notif| acc.push(notif.dossier) }).uniq
  end

  def procedure_id
    @procedure.nil? ? nil : @procedure.id
  end

  def dossiers_to_display
    service.dossiers_to_display
  end

  def preference_list_dossiers_filter
    @list_table_columns ||= @current_devise_profil.preference_list_dossiers.where(procedure: @procedure).order(:id)
  end

  def active_filter? preference
    return true if @procedure.nil? || preference.table != 'champs' || (preference.table == 'champs' && !preference.filter.blank?)

    preference_list_dossiers_filter.where(table: :champs).where.not(filter: '').size == 0
  end

  def all_state_total
    service.all_state.count
  end

  def nouveaux_total
    service.nouveaux.count
  end

  def suivi_total
    service.suivi.count
  end

  def filter_url
    @procedure.nil? ? backoffice_dossiers_filter_path(liste: liste) : backoffice_dossiers_procedure_filter_path(id: @procedure.id, liste: liste)
  end

  private

  def gestionnaire?
    @current_devise_profil.class == Gestionnaire
  end

  def user?
    @current_devise_profil.class == User
  end

  def base_url liste
    @procedure.nil? ? backoffice_dossiers_path(liste: liste) : backoffice_dossiers_procedure_path(id: @procedure.id, liste: liste)
  end

end
