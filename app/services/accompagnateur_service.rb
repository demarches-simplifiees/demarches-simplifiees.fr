class AccompagnateurService
  ASSIGN = 'assign'
  NOT_ASSIGN = 'not_assign'

  def self.change_assignement! accompagnateur, procedure, to
    if to == ASSIGN
      AssignTo.create(gestionnaire: accompagnateur, procedure: procedure)
    elsif to == NOT_ASSIGN
      AssignTo.delete_all(gestionnaire: accompagnateur, procedure: procedure)
    end
  end

  def self.build_default_column accompagnateur, procedure, to
    return unless to == ASSIGN
    return unless PreferenceListDossier.where(gestionnaire: accompagnateur, procedure: procedure).empty?

    accompagnateur.preference_list_dossiers.each do |pref|
      clone = pref.dup

      clone.procedure = procedure
      clone.save
    end
  end
end