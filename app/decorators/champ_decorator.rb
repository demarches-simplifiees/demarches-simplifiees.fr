class ChampDecorator < Draper::Decorator
  delegate_all

  def value
    return object.value == 'on' ? 'Oui' : 'Non' if type_champ == 'checkbox'
    return JSON.parse(object.value).join(', ')  if type_champ == 'multiple_drop_down_list' && !object.value.blank?
    object.value
  end

  def description_with_links
    description.gsub(URI.regexp, '<a target="_blank" href="\0">\0</a>').html_safe if description
  end

end
