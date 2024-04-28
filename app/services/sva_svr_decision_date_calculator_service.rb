# frozen_string_literal: true

class SVASVRDecisionDateCalculatorService
  attr_reader :dossier, :procedure, :unit, :period, :resume_method

  EMPTY_DOSSIER = Struct.new(:depose_at) do
    def corrections
      []
    end
  end

  def self.decision_date_from_today(procedure)
    dossier = EMPTY_DOSSIER.new(Date.current)
    new(dossier, procedure).decision_date
  end

  def initialize(dossier, procedure)
    @dossier = dossier
    @procedure = procedure

    config = procedure.sva_svr_configuration
    @unit = config.unit.to_sym
    @period = config.period.to_i
    @resume_method = config.resume.to_sym
  end

  def decision_date
    duration = calculate_duration

    start_date = determine_start_date + 1.day
    correction_delay = calculate_correction_delay(start_date)

    start_date + duration + correction_delay
  end

  private

  def calculate_duration
    case unit
    when :days
      period.days
    when :weeks
      period.weeks
    when :months
      period.months
    end
  end

  def determine_start_date
    return dossier.depose_at.to_date if dossier.corrections.empty?
    return latest_correction_date if resume_method == :reset
    return latest_incomplete_correction_date if dossier.corrections.any?(&:dossier_incomplete?)

    dossier.depose_at.to_date
  end

  def latest_incomplete_correction_date
    correction_date dossier.corrections.filter(&:dossier_incomplete?).max_by(&:resolved_at)
  end

  def latest_correction_date
    correction_date dossier.corrections.max_by(&:resolved_at)
  end

  def calculate_correction_delay(start_date)
    dossier.corrections.sum do |correction|
      resolved_date = correction_date(correction)
      next 0 unless resolved_date > start_date

      (resolved_date + 1.day - correction.created_at.to_date).days # restart from next day after resolution
    end
  end

  def correction_date(correction)
    # NOTE: when correction is not resolved, assume it could be done today
    # so interfaces could show how many days are remaining after correction
    correction.resolved_at&.to_date || Date.current
  end
end
