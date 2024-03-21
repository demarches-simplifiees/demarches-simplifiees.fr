class ApplicationComponent < ViewComponent::Base
  include ViewComponent::Translatable
  include FlipperHelper

  delegate :rich_text_area_tag, :dsfr_icon, to: :helpers

  def current_user
    controller.current_user
  end

  def current_administrateur
    controller.current_administrateur
  end

  def current_gestionnaire
    controller.current_gestionnaire
  end
end
