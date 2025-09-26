# frozen_string_literal: true

class DossierTree::RepeaterComponent < ApplicationComponent
  attr_reader :repeater, :seen_at, :profile

  def initialize(repeater:, seen_at:, profile:)
    @repeater = repeater
    @seen_at = seen_at
    @profile = profile
  end

  private

  def rows
    repeater.rows
  end
end
