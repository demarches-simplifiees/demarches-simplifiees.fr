class PreremplissageService

  def parse_into(param,session)
    session[:inject] = JSON.parse(param)
    session
  end

  def fill_from(session,dossier)
    inject = session[:inject]
    if inject
      inject.each do |key,value|
        champs = dossier.champs.find_all { |c| c.libelle == key}
        if champs && (champ = champs.first)
          champ.value = value
          champ.save
        end
      end
    end
    dossier
  end

end
