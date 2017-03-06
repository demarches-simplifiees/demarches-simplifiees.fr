class AdminProceduresShowFacades
  def initialize procedure
    @procedure = procedure
  end

  def procedure
    @procedure
  end

  def dossiers
    @procedure.dossiers.where.not(state: :draft)
  end

  def dossiers_for_pie_highchart
    dossiers.where.not(state: :draft, archived: true).group(:state).count
      .reduce({}) do |acc, (key, val)|
      translated_key = DossierDecorator.case_state_fr(key)
      acc[translated_key].nil? ? acc[translated_key] = val : acc[translated_key] += val
      acc
    end
  end

  def dossiers_archived_by_state_total
    dossiers.select('state, count(*) as total').where(archived: true).where.not(state: :termine).group(:state).order(:state).decorate
  end

  def dossiers_archived_total
    dossiers.where(archived: true).where.not(state: :termine).size
  end

  def dossiers_total
    dossiers.size
  end

  def dossiers_waiting_gestionnaire_total
    dossiers.waiting_for_gestionnaire.size
  end

  def dossiers_waiting_user_total
    dossiers.waiting_for_user.size
  end

  def dossiers_termine_total
    dossiers.where(state: :termine).size
  end
end