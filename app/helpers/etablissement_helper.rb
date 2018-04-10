module EtablissementHelper
  def pretty_currency(capital_social)
    number_to_currency(capital_social, locale: :fr)
  end
end
