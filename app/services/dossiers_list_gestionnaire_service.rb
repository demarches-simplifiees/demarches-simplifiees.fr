class DossiersListGestionnaireService
  def initialize current_devise_profil, liste
    @current_devise_profil = current_devise_profil
    @liste = liste
  end

  def dossiers_to_display
    {'nouveaux' => nouveaux,
     'a_traiter' => waiting_for_gestionnaire,
     'en_attente' => waiting_for_user,
     'deposes' => deposes,
     'a_instruire' => a_instruire,
     'termine' => termine,
     'suivi' => suivi}[@liste]
  end

  def nouveaux
    @nouveaux ||= @current_devise_profil.dossiers.nouveaux
  end

  def waiting_for_gestionnaire
    @waiting_for_gestionnaire ||= @current_devise_profil.dossiers.waiting_for_gestionnaire
  end

  def waiting_for_user
    @waiting_for_user ||= @current_devise_profil.dossiers.waiting_for_user
  end

  def deposes
    @deposes ||= @current_devise_profil.dossiers.deposes
  end

  def a_instruire
    @a_instruire ||= @current_devise_profil.dossiers.a_instruire
  end

  def termine
    @termine ||= @current_devise_profil.dossiers.termine
  end

  def suivi
    @suivi ||= @current_devise_profil.dossiers_follow
  end
end