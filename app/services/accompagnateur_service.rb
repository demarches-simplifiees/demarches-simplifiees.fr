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
end