class ChampsService
  def self.save_formulaire champs, params, check_mandatory=true
    errors = Array.new

    champs.each do |champ|
      champ.value = params[:champs]["'#{champ.id}'"]

      if champ.type_champ == 'datetime'
        champ.value = params[:champs]["'#{champ.id}'"]+
            ' ' +
            params[:time_hour]["'#{champ.id}'"] +
            ':' +
            params[:time_minute]["'#{champ.id}'"]
      end

      if check_mandatory
        if champ.mandatory? && (champ.value.nil? || champ.value.blank?)
          errors.push({message: "Le champ #{champ.libelle} doit être rempli."})
        end
      end

      champ.save if champ.changed?
    end

    errors
  end
end
