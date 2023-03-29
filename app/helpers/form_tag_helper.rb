module FormTagHelper
  # from Rails 7 ActionView::Helpers::FormTagHelper
  # https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-field_id
  # Should be removed when we upgrade to Rails 7
  def field_id(object_name, method_name, *suffixes, index: nil, namespace: nil)
    if object_name.respond_to?(:model_name)
      object_name = object_name.model_name.singular
    end

    sanitized_object_name = object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").delete_suffix("_")

    sanitized_method_name = method_name.to_s.delete_suffix("?")

    [
      namespace,
      sanitized_object_name.presence,
      (index unless sanitized_object_name.empty?),
      sanitized_method_name,
      *suffixes
    ].tap(&:compact!).join("_")
  end

  # from Rails 7 ActionView::Helpers::FormTagHelper
  # https://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-field_name
  # Should be removed when we upgrade to Rails 7
  def field_name(object_name, method_name, *method_names, multiple: false, index: nil)
    names = method_names.map! { |name| "[#{name}]" }.join

    # a little duplication to construct fewer strings
    case
    when object_name.blank?
      "#{method_name}#{names}#{multiple ? "[]" : ""}"
    when index
      "#{object_name}[#{index}][#{method_name}]#{names}#{multiple ? "[]" : ""}"
    else
      "#{object_name}[#{method_name}]#{names}#{multiple ? "[]" : ""}"
    end
  end
end
