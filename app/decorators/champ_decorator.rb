class ChampDecorator < Draper::Decorator
  delegate_all

  def value
    if type_champ == 'checkbox'
      return object.value == 'on' ? 'Oui' : 'Non'
    end
    object.value
  end
end