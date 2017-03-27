class UserDecorator < Draper::Decorator
  delegate_all

  def gender_fr
    return 'M.' if gender == 'male'
    return 'Mme' if gender == 'female'
  end

  def birthdate_fr
    birthdate.strftime('%d/%m/%Y')
  end
end
