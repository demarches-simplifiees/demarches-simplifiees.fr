class DossiersListUserService
  def initialize current_devise_profil, liste
    @current_devise_profil = current_devise_profil
    @liste = liste
  end

  def dossiers_to_display
    {'nouveaux' => nouveaux,
     'a_traiter' => waiting_for_user,
     'en_attente' => waiting_for_gestionnaire,
     'valides' => valides,
     'en_instruction' => en_instruction,
     'termine' => termine,
     'invite' => invite}[@liste]
  end

  def nouveaux
    @nouveaux ||= @current_devise_profil.dossiers.nouveaux
  end

  def waiting_for_gestionnaire
    @waiting_for_gestionnaire ||= @current_devise_profil.dossiers.waiting_for_gestionnaire
  end

  def waiting_for_user
    @waiting_for_user ||= @current_devise_profil.dossiers.waiting_for_user_without_validated
  end

  def invite
    @invite ||= @current_devise_profil.invites
  end

  def valides
    @valides ||= @current_devise_profil.dossiers.valides
  end

  def en_instruction
    @en_instruction ||= @current_devise_profil.dossiers.en_instruction
  end

  def termine
    @termine ||= @current_devise_profil.dossiers.termine
  end
end