class AccompagnateurService
  ASSIGN = 'assign'
  NOT_ASSIGN = 'not_assign'

  def initialize accompagnateur, procedure, to
    @accompagnateur = accompagnateur
    @procedure = procedure
    @to = to
  end

  def change_assignement!
    if @to == ASSIGN
      AssignTo.create(gestionnaire: @accompagnateur, procedure: @procedure)
    elsif @to == NOT_ASSIGN
      AssignTo.delete_all(gestionnaire: @accompagnateur, procedure: @procedure)
    end
  end

  def build_default_column
    return unless @to == ASSIGN
    return unless PreferenceListDossier.where(gestionnaire: @accompagnateur, procedure: @procedure).empty?

    @accompagnateur.build_default_preferences_list_dossier @procedure.id
  end
end