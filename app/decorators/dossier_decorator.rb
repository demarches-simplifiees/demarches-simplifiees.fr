class DossierDecorator < Draper::Decorator
  delegate_all

  def date_fr
    date_previsionnelle.to_date.strftime('%d/%m/%Y')
  rescue
    'dd/mm/YYYY'
  end
end
