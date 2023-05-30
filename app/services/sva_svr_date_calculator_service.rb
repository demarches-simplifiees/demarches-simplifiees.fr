class SVASVRDateCalculatorService
  attr_reader :dossier, :procedure

  def initialize(dossier, procedure)
    @dossier = dossier
    @procedure = procedure
  end

  def calculate
    config = procedure.sva_svr_configuration
    unit = config.unit.to_sym
    period = config.period.to_i

    case unit
    when :days
      dossier.depose_at.to_date + period.days
    when :weeks
      dossier.depose_at.to_date + period.weeks
    when :months
      dossier.depose_at.to_date + period.months
    end
  end
end
