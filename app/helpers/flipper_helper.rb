module FlipperHelper
  def feature_enabled?(feature_name)
    Flipper.enabled?(feature_name, current_user)
  end

  def feature_enabled_for?(feature_name, item)
    Flipper.enabled?(feature_name, item)
  end
end
