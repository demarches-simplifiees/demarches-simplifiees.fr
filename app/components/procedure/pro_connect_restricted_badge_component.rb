# frozen_string_literal: true

class Procedure::ProConnectRestrictedBadgeComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    @procedure.pro_connect_restricted?
  end
end
