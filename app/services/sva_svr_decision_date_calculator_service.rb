class SVASVRDecisionDateCalculatorService
  attr_reader :dossier, :procedure, :unit, :period, :resume_method

  def initialize(dossier, procedure)
    @dossier = dossier
    @procedure = procedure

    config = procedure.sva_svr_configuration
    @unit = config.unit.to_sym
    @period = config.period.to_i
    @resume_method = config.resume.to_sym
  end

  def decision_date
    base_date = determine_base_date

    duration = case unit
    when :days
      period.days
    when :weeks
      period.weeks
    when :months
      period.months
    end

    base_date + duration
  end

  private

  def determine_base_date
    return dossier.depose_at.to_date + total_correction_delay if resume_method == :continue

    if dossier.corrections.any?
      most_recent_correction_date
    else
      dossier.depose_at.to_date
    end
  end

  def total_correction_delay
    dossier.corrections.sum do |correction|
      # If the correction is not resolved, we use the current date
      # so interfaces could calculate how many remaining days
      resolved_date = correction.resolved_at&.to_date || Date.current

      (resolved_date - correction.created_at.to_date).days
    end
  end

  def most_recent_correction_date
    return Date.current if dossier.pending_correction?

    dossier.corrections.max_by(&:resolved_at).resolved_at.to_date
  end
end
