# frozen_string_literal: true

class Procedure::EstimatedDelayComponent < ApplicationComponent
  delegate :distance_of_time_in_words, to: :helpers

  def initialize(procedure:)
    @procedure = procedure
    @fastest, @mean, @slow = @procedure.stats_usual_traitement_time
  end

  def estimation_present?
    @fastest && @mean && @slow
  end

  def render?
    return false if @procedure.declarative_accepte?

    estimation_present?
  end

  def cleaned_nearby_estimation
    [@fastest, @mean, @slow]
      .map { distance_of_time_in_words(_1) }
      .uniq
      .zip(['fast_html', 'mean_html', 'slow_html'])
      .each do |estimation, i18n_key|
        yield(estimation, i18n_key)
      end
  end
end
