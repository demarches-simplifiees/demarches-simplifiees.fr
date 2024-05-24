class Migrations::BatchUpdatePaysValuesJob < ApplicationJob
  UNUSUAL_COUNTRY_NAME_MATCHER = {
    "ACORES, MADERE" => "Portugal",
    "ALASKA" => "États-Unis",
    "ANTILLES NEERLANDAISES" => "Pays-Bas",
    "BIELORUSSIE" => "Bélarus",
    "BONAIRE, SAINT EUSTACHE ET SABA" => "Bonaire, Saint-Eustache et Saba",
    "BURKINA" => "Burkina Faso",
    "CAIMANES (ILES)" => "îles Caïmans",
    "CAMEROUN ET TOGO" => "Cameroun",
    "CANARIES (ILES)" => "Espagne",
    "CENTRAFRICAINE (REPUBLIQUE)" => "République centrafricaine",
    "CHRISTMAS (ILE)" => "Christmas, Île",
    "CONGO (REPUBLIQUE DEMOCRATIQUE)" => "République démocratique du Congo",
    "COOK (ILES)" => "îles Cook",
    "COREE (REPUBLIQUE DE)" => "Corée, République de",
    "COREE (REPUBLIQUE POPULAIRE DEMOCRATIQUE DE)" => "Corée, République populaire démocratique de",
    "COREE" => "Corée, République de",
    "DOMINICAINE (REPUBLIQUE)" => "République dominicaine",
    "ETATS MALAIS NON FEDERES" => "Malaisie",
    "FEROE (ILES)" => "îles Féroé",
    "GUYANE" => "France",
    "HAWAII (ILES)" => "États-Unis",
    "HEARD ET MACDONALD (ILES)" => "îles Heard-et-MacDonald",
    "ILES PORTUGAISES DE L'OCEAN INDIEN" => "Portugal",
    "IRLANDE, ou EIRE" => "Irlande",
    "KAMTCHATKA" => "Russie, Fédération de",
    "LA REUNION" => "Réunion, Île de la",
    "LABRADOR" => "Canada",
    "MACEDOINE DU NORD (REPUBLIQUE DE)" => "Macédoine du Nord",
    "MALOUINES, OU FALKLAND (ILES)" => "Malouines, Îles (Falkland)",
    "MAN (ILE)" => "Île de Man",
    "MARIANNES DU NORD (ILES)" => "Îles Mariannes du Nord",
    "MARSHALL (ILES)" => "Îles Marshall",
    "OCEAN INDIEN (TERRITOIRE BRITANNIQUE DE L')" => "Royaume-Uni",
    "PALESTINE (Etat de)" => "Palestine, État de",
    "POSSESSIONS BRITANNIQUES AU PROCHE-ORIENT" => "Royaume-Uni",
    "PROVINCES ESPAGNOLES D'AFRIQUE" => "Espagne",
    "REPUBLIQUE DEMOCRATIQUE ALLEMANDE" => "Allemagne",
    "REPUBLIQUE FEDERALE D'ALLEMAGNE" => "Allemagne",
    "RUSSIE" => "Russie, Fédération de",
    "SAINT-MARTIN" => "Saint-Martin (partie française)",
    "SAINT-VINCENT-ET-LES GRENADINES" => "Saint-Vincent-et-les-Grenadines",
    "SAINTE HELENE, ASCENSION ET TRISTAN DA CUNHA" => "Sainte-Hélène, Ascension et Tristan da Cunha",
    "SALOMON (ILES)" => "Salomon, Îles",
    "SAMOA OCCIDENTALES" => "Samoa",
    "SIBERIE" => "Russie, Fédération de",
    "SOUDAN ANGLO-EGYPTIEN, KENYA, OUGANDA" => "Ouganda",
    "SYRIE" => "Syrienne, République arabe",
    "TANGER" => "Maroc",
    "TCHECOSLOVAQUIE" => "Tchéquie",
    "TCHEQUE (REPUBLIQUE)" => "Tchéquie",
    "TERR. DES ETATS-UNIS D'AMERIQUE EN AMERIQUE" => "États-Unis",
    "TERR. DES ETATS-UNIS D'AMERIQUE EN OCEANIE" => "États-Unis",
    "TERR. DU ROYAUME-UNI DANS L'ATLANTIQUE SUD" => "Royaume-Uni",
    "TERRE-NEUVE" => "Canada",
    "TERRITOIRES DU ROYAUME-UNI AUX ANTILLES" => "Royaume-Uni",
    "TURKESTAN RUSSE" => "Russie, Fédération de",
    "TURKS ET CAIQUES (ILES)" => "îles Turques-et-Caïques",
    "TURQUIE D'EUROPE" => "Turquie",
    "VATICAN, ou SAINT-SIEGE" => "Saint-Siège (état de la cité du Vatican)",
    "VIERGES BRITANNIQUES (ILES)" => "Îles Vierges britanniques",
    "VIERGES DES ETATS-UNIS (ILES)" => "Îles Vierges des États-Unis",
    "VIET NAM DU NORD" => "Viêt Nam",
    "VIET NAM DU SUD" => "Viêt Nam",
    "WALLIS-ET-FUTUNA" => "Wallis et Futuna",
    "YEMEN (REPUBLIQUE ARABE DU)" => "Yémen",
    "YEMEN DEMOCRATIQUE" => "Yémen",
    "ZANZIBAR" => "Tanzanie"
  }

  private_constant :UNUSUAL_COUNTRY_NAME_MATCHER

  def perform(ids)
    ids.each do |id|
      pays_champ = Champs::PaysChamp.find(id)

      next if pays_champ.valid?(pays_champ.public? ? :champs_public_value : :champs_private_value)
      code = APIGeoService.country_code(pays_champ.value)
      value = if code.present?
        APIGeoService.country_name(code)
      else
        UNUSUAL_COUNTRY_NAME_MATCHER[pays_champ.value]
      end

      if value.present? || !pays_champ.required?
        associated_country_code = APIGeoService.country_code(value)
        pays_champ.update_columns(value: value, external_id: associated_country_code)
      end
    end
  end
end
