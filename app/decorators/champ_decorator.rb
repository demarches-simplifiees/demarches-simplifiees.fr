class ChampDecorator < Draper::Decorator
  delegate_all

  def value
    if type_champ == "date" && object.value.present?
      Date.parse(object.value).strftime("%d/%m/%Y")
    elsif type_champ == 'yes_no'
      if object.value == 'true'
        'Oui'
      elsif object.value == 'false'
        'Non'
      end
    else
      object.value
    end
  end

  def description_with_links
    description.gsub(URI.regexp, '<a target="_blank" href="\0">\0</a>') if description
  end
end
