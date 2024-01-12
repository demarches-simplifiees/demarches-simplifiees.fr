class ApplicationComponent < ViewComponent::Base
  include ViewComponent::Translatable
  include FlipperHelper

  def current_user
    controller.current_user
  end

  def current_administrateur
    controller.current_administrateur
  end
end
