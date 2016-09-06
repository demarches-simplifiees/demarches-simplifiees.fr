class DossiersListGestionnaireService
  def initialize current_devise_profil, liste, procedure = nil
    @current_devise_profil = current_devise_profil
    @liste = liste
    @procedure = procedure
  end

  def dossiers_to_display
    {'nouveaux' => nouveaux,
     'a_traiter' => waiting_for_gestionnaire,
     'en_attente' => waiting_for_user,
     'deposes' => deposes,
     'a_instruire' => a_instruire,
     'termine' => termine}[@liste]
  end

  def nouveaux
    @nouveaux ||= filter_dossiers.nouveaux
  end

  def waiting_for_gestionnaire
    @waiting_for_gestionnaire ||= filter_dossiers.waiting_for_gestionnaire
  end

  def waiting_for_user
    @waiting_for_user ||= filter_dossiers.waiting_for_user
  end

  def deposes
    @deposes ||= filter_dossiers.deposes
  end

  def a_instruire
    @a_instruire ||= filter_dossiers.a_instruire
  end

  def termine
    @termine ||= filter_dossiers.termine
  end

  def filter_dossiers
    @procedure.nil? ? @current_devise_profil.dossiers : @procedure.dossiers
  end
end