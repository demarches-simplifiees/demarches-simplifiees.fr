class ApplicationComponent < ViewComponent::Base
  include ViewComponent::Translatable

  def class_names(class_names)
    class_names.to_a.filter_map { |(class_name, flag)| class_name if flag }.join(' ')
  end
end
