class AdminProceduresShowFacades
  def initialize(procedure)
    @procedure = procedure
  end

  def procedure
    @procedure
  end

  def dossiers
    @procedure.dossiers.state_not_brouillon
  end
end
