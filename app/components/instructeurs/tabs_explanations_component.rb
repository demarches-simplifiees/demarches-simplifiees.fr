# frozen_string_literal: true

class Instructeurs::TabsExplanationsComponent < ApplicationComponent
  attr_reader :element

  def initialize(element: nil)
    @element = element
  end

  def render_button?
    element.nil? || element == :button
  end

  def render_dialog?
    element.nil? || element == :dialog
  end
end
