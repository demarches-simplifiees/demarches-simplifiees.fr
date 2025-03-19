class Procedure::PendingRepublishComponent < ApplicationComponent
  def initialize(procedure:, render_if:)
    @procedure = procedure
    @render_if = render_if
  end

  def render?
    @render_if
  end
end
