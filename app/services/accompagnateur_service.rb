class AccompagnateurService
  ASSIGN = 'assign'
  NOT_ASSIGN = 'not_assign'

  def initialize accompagnateur, procedure, to
    @accompagnateur = accompagnateur
    @procedure = procedure
    @to = to
  end

  def change_assignement!
    case @to
    when ASSIGN
      AssignTo.create(gestionnaire: @accompagnateur, procedure: @procedure)
    when NOT_ASSIGN
      AssignTo.where(gestionnaire: @accompagnateur, procedure: @procedure).delete_all
    end
  end
end
