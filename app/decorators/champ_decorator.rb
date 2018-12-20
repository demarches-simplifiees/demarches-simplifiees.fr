class ChampDecorator < Draper::Decorator
  delegate_all

  def value
    if type_champ == TypeDeChamp.type_champs.fetch(:date) && object.value.present?
      Date.parse(object.value).strftime("%d/%m/%Y")
    elsif type_champ.in? [TypeDeChamp.type_champs.fetch(:checkbox), TypeDeChamp.type_champs.fetch(:engagement)]
      object.value == 'on' ? 'Oui' : 'Non'
    elsif type_champ == TypeDeChamp.type_champs.fetch(:yes_no)
      if object.value == 'true'
        'Oui'
      elsif object.value == 'false'
        'Non'
      end
    elsif type_champ == TypeDeChamp.type_champs.fetch(:multiple_drop_down_list) && object.value.present?
      JSON.parse(object.value).join(', ')
    else
      object.value
    end
  end
end
