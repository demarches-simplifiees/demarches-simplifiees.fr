class ApplicationComponent < ViewComponent::Base
  include ViewComponent::Translatable
  include FlipperHelper

  # Takes a Hash of { class_name: boolean }.
  # Returns truthy class names in an array. Array can be passed as-it in rails helpers,
  # and is still manipulable if needed.
  def class_names(class_names)
    class_names.filter { _2 }.keys
  end

  def current_user
    controller.current_user
  end

  def current_administrateur
    controller.current_administrateur
  end
end
