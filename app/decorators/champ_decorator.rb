class ChampDecorator < Draper::Decorator
  delegate_all

  def value
    if type_champ == 'checkbox'
      return object.value == 'on' ? 'Oui' : 'Non'
    end
    object.value
  end

  def description_with_links
    description.gsub(URI.regexp, '<a target="_blank" href="\0">\0</a>').html_safe if description
  end

end
