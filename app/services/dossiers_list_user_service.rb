class DossiersListUserService
  def initialize current_devise_profil, liste
    @current_devise_profil = current_devise_profil
    @liste = liste
  end

  def dossiers_to_display
    {'brouillon' => brouillon,
     'a_traiter' => en_construction,
     'en_instruction' => en_instruction,
     'termine' => termine,
     'invite' => invite,
     'all_state' => all_state}[@liste]
  end

  def self.dossiers_liste_libelle
    ['brouillon', 'a_traiter', 'en_instruction', 'termine', 'invite', 'all_state']
  end

  def all_state
    @all_state ||= @current_devise_profil.dossiers.all_state
  end

  def brouillon
    @brouillon ||= @current_devise_profil.dossiers.brouillon
  end

  def en_construction
    @en_construction ||= @current_devise_profil.dossiers.en_construction
  end

  def invite
    @invite ||= @current_devise_profil.invites
  end

  def en_instruction
    @en_instruction ||= @current_devise_profil.dossiers.en_instruction
  end

  def termine
    @termine ||= @current_devise_profil.dossiers.termine
  end
end
