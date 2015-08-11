class EntrepriseDecorator < Draper::Decorator
  delegate_all

  def raison_sociale_or_name
    raison_sociale.nil? ? nom + '' + prenom : raison_sociale
  end

  def code_effectif_entreprise_libelle

    case code_effectif_entreprise.to_s
      when '00'
        '0 salarié'
      when '01'
        '1 ou 2 salariés'
      when '02'
        '3 à 5 salariés'
      when '03'
        '6 à 9 salariés'
      when '11'
        '10 à 19 salariés'
      when '12'
        '20 à 49 salariés'
      when '21'
        '50 à 99 salariés'
      when '22'
        '100 à 199 salariés'
      when '31'
        '200 à 249 salariés'
      when '32'
        '250 à 499 salariés'
      when '41'
        '500 à 999 salariés'
      when '42'
        '1 000 à 1 999 salariés'
      when '51'
        '2 000 à 4 999 salariés'
      when '52'
        '5 000 à 9 999 salariés'
      when '53'
        '10 000 salariés et plus'
    end
  end
end