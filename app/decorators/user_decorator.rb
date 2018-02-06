class UserDecorator < Draper::Decorator
  delegate_all

  def gender_fr
    case gender
    when 'male'
      'M.'
    when 'female'
      'Mme'
    end
  end
end
