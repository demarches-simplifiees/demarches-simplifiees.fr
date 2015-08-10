class EtablissementDecorator < Draper::Decorator
  delegate_all

  def siege_social_true_false
    siege_social? ? 'Cet établissement est le siège social' : 'Cet établissement n\'est pas le siège social'
  end
end