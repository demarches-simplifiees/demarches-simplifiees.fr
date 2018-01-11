module EntrepriseHelper
  def raison_sociale_or_name(entreprise)
    entreprise.raison_sociale.blank? ? "#{entreprise.nom} #{entreprise.prenom}" : entreprise.raison_sociale
  end

  def effectif(entreprise)
    {
      'NN' => "Unités non employeuses (pas de salarié au cours de l'année de référence et pas d'effectif au 31/12).",
      '00' => "0 salarié (n'ayant pas d'effectif au 31/12 mais ayant employé des salariés au cours de l'année de référence)",
      '01' => '1 ou 2 salariés',
      '02' => '3 à 5 salariés',
      '03' => '6 à 9 salariés',
      '11' => '10 à 19 salariés',
      '12' => '20 à 49 salariés',
      '21' => '50 à 99 salariés',
      '22' => '100 à 199 salariés',
      '31' => '200 à 249 salariés',
      '32' => '250 à 499 salariés',
      '41' => '500 à 999 salariés',
      '42' => '1 000 à 1 999 salariés',
      '51' => '2 000 à 4 999 salariés',
      '52' => '5 000 à 9 999 salariés',
      '53' => '10 000 salariés et plus'
    }[entreprise.code_effectif_entreprise]
  end

  def pretty_capital_social(entreprise)
    number_to_currency(entreprise.capital_social, delimiter: ' ', unit: '€', format: '%n %u')
  end
end