class ChampDecorator < Draper::Decorator

  def value
    if type_champ == 'checkbox'
      return object.value == 'on' ? 'Oui' : 'Non'
    end
    object.value
  end

  def type_champ
    object.type_de_champ.type_champ
  end
end