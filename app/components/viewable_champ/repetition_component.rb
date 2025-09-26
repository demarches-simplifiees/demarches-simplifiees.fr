# frozen_string_literal: true

class ViewableChamp::RepetitionComponent < ApplicationComponent
  include ApplicationHelper
  attr_reader :repetition, :rows, :seen_at, :profile

  def initialize(repetition:, demande_seen_at:, profile:)
    @repetition, @seen_at, @profile = repetition, demande_seen_at, profile
    @rows = repetition.new_rows
  end
end
