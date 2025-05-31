class ApplicationComponent < ViewComponent::Base
  include ViewComponent::Translatable
  include FlipperHelper

  delegate :rich_text_area_tag, :dsfr_icon, to: :helpers

  def current_user
    controller.current_user
  end

  def current_instructeur
    controller.current_instructeur
  end

  def current_administrateur
    controller.current_administrateur
  end

  def current_gestionnaire
    controller.current_gestionnaire
  end

  def current_super_admin
    controller.current_super_admin
  end
end
