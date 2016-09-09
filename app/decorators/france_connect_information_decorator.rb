class FranceConnectInformationDecorator < Draper::Decorator
  delegate_all

  def gender_fr
    gender == 'female' ? 'Mme' : 'Mr'
  end
end
