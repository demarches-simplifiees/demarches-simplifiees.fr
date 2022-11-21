class ApplicationComponent < ViewComponent::Base
  include ViewComponent::Translatable
  include FlipperHelper

  def class_names(class_names)
    class_names.to_a.filter_map { |(class_name, flag)| class_name if flag }.join(' ')
  end

  def current_user
    controller.current_user
  end

  def current_administrateur
    controller.current_administrateur
  end
end
