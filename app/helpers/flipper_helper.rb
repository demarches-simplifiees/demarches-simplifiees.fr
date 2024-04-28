# frozen_string_literal: true

module FlipperHelper
  def feature_enabled?(feature_name)
    Flipper.enabled?(feature_name, current_user)
  end
end
