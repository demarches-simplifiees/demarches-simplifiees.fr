class UserDecorator < Draper::Decorator
  delegate_all

  def gender_fr
    return 'Mr' if gender == 'male'
    return 'Mme' if gender == 'female'
  end

  def birthdate_fr
    birthdate.try { strftime('%d/%m/%Y') }
  end
end
