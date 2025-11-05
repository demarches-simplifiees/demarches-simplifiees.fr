# frozen_string_literal: true

class Procedure::Card::ProConnectRestrictedComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    feature_enabled?(:pro_connect_restricted)
  end

  def restriction_label
    case @procedure.pro_connect_restriction
    when 'none'
      t('.none')
    when 'instructeurs'
      t('.instructeurs')
    when 'all'
      t('.all')
    else
      t('.none')
    end
  end

  def badge_state
    @procedure.pro_connect_restriction_none? ? :default : :success
  end
end
