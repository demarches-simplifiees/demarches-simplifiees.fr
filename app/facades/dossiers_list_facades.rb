class DossiersListFacades
  def initialize current_devise_profil, liste
    @current_devise_profil = current_devise_profil
    @liste = liste
  end

  def service
    if gestionnaire?
      @service ||= DossiersListGestionnaireService.new @current_devise_profil, @liste
    elsif user?
      @service ||= DossiersListUserService.new @current_devise_profil, @liste
    end
  end

  def liste
    @liste
  end

  def dossiers_to_display
    service.dossiers_to_display
  end

  def nouveaux_class
    (@liste == 'nouveaux' ? 'active' : '')
  end

  def a_traiter_class
    (@liste == 'a_traiter' ? 'active' : '')
  end

  def en_attente_class
    (@liste == 'en_attente' ? 'active' : '')
  end

  def deposes_class
    (@liste == 'deposes' ? 'active' : '')
  end

  def valides_class
    (@liste == 'valides' ? 'active' : '')
  end

  def en_instruction_class
    (@liste == 'en_instruction' ? 'active' : '')
  end

  def a_instruire_class
    (@liste == 'a_instruire' ? 'active' : '')
  end

  def termine_class
    (@liste == 'termine' ? 'active' : '')
  end

  def suivi_class
    (@liste == 'suivi' ? 'active' : '')
  end

  def invite_class
    (@liste == 'invite' ? 'active' : '')
  end

  def nouveaux_total
    service.nouveaux.count
  end

  def a_traiter_total
    service.waiting_for_gestionnaire.count if gestionnaire?
    service.waiting_for_user.count if user?
  end

  def en_attente_total
    service.waiting_for_user.count if gestionnaire?
    service.waiting_for_gestionnaire.count if user?
  end

  def valides_total
    service.valides.count
  end

  def deposes_total
    service.deposes.count
  end

  def en_instruction_total
    service.en_instruction.count
  end

  def a_instruire_total
    service.a_instruire.count
  end

  def termine_total
    service.termine.count
  end

  def suivi_total
    service.suivi.count
  end

  def invite_total
    service.invite.count
  end

  private

  def gestionnaire?
    @current_devise_profil.class == Gestionnaire
  end

  def user?
    @current_devise_profil.class == User
  end
end