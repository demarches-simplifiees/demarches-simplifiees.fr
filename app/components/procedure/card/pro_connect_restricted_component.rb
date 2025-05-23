# frozen_string_literal: true

class Procedure::Card::ProConnectRestrictedComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    feature_enabled?(:pro_connect_restricted)
  end
end
