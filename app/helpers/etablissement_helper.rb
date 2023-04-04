module EtablissementHelper
  def pretty_siret(siret)
    "#{siret[0..2]} #{siret[3..5]} #{siret[6..8]} #{siret[9..]}"
  end

  def pretty_currency(capital_social, unit: '€')
    number_to_currency(capital_social, locale: :fr, unit: unit, precision: 0)
  end

  def pretty_currency_unit(unit)
    dict = { 'kEuros' => 'k€' }
    dict[unit]
  end

  def raison_sociale_or_name(etablissement)
    etablissement.association_titre.presence ||
      etablissement.enseigne.presence ||
      etablissement.entreprise_raison_sociale.presence ||
      "#{etablissement.entreprise_nom} #{etablissement.entreprise_prenom}"
  end

  def effectif(etablissement)
    {
      'NN' => "Unités non employeuses (pas de salarié au cours de l'année de référence et pas d’effectif au 31/12).",
      '00' => "0 salarié (n'ayant pas d’effectif au 31/12 mais ayant employé des salariés au cours de l'année de référence)",
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
    }[etablissement.entreprise_code_effectif_entreprise]
  end

  def pretty_date_exercice(date)
    date.sub(/(?<year>\d{4})(?<month>\d{2})/, '\k<year>') if date.present?
  end

  def humanized_entreprise_etat_administratif(etablissement)
    case etablissement.entreprise_etat_administratif&.to_sym
    when :actif
      "en activité"
    when :fermé
      "fermé"
    end
  end
end
