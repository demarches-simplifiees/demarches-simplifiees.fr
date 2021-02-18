require 'spec_helper'

describe APIEntreprise::PfEtablissementAdapter do
  let(:procedure_id) { 33 }

  context 'Numéro TAHITI valide', vcr: { cassette_name: 'pf_api_entreprise' } do
    let(:siret) { '075390' }
    let!(:adresse) {
      [
        "BP 130, 98713 PAPEETE BP, 115, rue Dumont d'Urville, quartier Orovini, Papeete",
        "BP 130, 98713 PAPEETE BP, Centre villeRaiatea, Uturoa",
        "BP 130, 98713 PAPEETE BP, rue Tihoni Tefaatau, immeuble SCI Taaone, Pirae",
        "BP 130, 98713 PAPEETE BP, Lotissement zone industrielle de PunaruuLot A, Punaauia",
        "BP 130, 98713 PAPEETE BP, Route de la pointe VénusDomaine Fritch, Mahina",
        "BP 130, 98713 PAPEETE BP, Terre domanialeNuku Hiva, Taiohae",
        "BP 130, 98713 PAPEETE BP, Hall du rez-de-chaussée de l'aéroport, Faaa",
        "BP 130, 98713 PAPEETE BP, 415, Boulevard Pomare, immeuble Vaiete, Papeete",
        "BP 130, 98713 PAPEETE BP, Lots 1 et 2 de la Terre FareoaHuahine, Fare",
        "BP 130, 98713 PAPEETE BP, Terre Mataupuna n°2479Hiva Oa, Atuona",
        "BP 130, 98713 PAPEETE BP, Centre commercial Temahame Nui de Taravao, Afaahiti",
        "BP 130, 98713 PAPEETE BP, Centre commercial de MaharepaQrt Orovau, Paopao",
        "BP 130, 98713 PAPEETE BP, Fare UteImm Le Cail, Papeete",
        "BP 130, 98713 PAPEETE BP, Centre communal de Ua Pou, Hakahau",
        "BP 130, 98713 PAPEETE BP, Pk 36Centre commercial de Apatea, Papara",
        "BP 130, 98713 PAPEETE BP, Terre Onanae 6Rurutu, Moerai",
        "BP 130, 98713 PAPEETE BP, Terre Taamotu 1, Nunue",
        "BP 130, 98713 PAPEETE BP, Complexe municipalTubuai, Mataura",
        "BP 130, 98713 PAPEETE BP, Boulevard Pomare, quartier du Commerce, Papeete",
        "BP 130, 98713 PAPEETE BP, Lot communal de Tiputa, Rangiroa",
        "BP 130, 98713 PAPEETE BP, Rte de l'ancienne mairieFace centre tavararo - Terre Tehorua 2 parcelle A, Faaa",
        "BP 130, 98713 PAPEETE BP, Rue Dumont d'Urville(Parking), Papeete",
        "BP 130, 98713 PAPEETE BP, Patio - Terre MainanuiTahaa, Iripau",
        "BP 130, 98713 PAPEETE BP, Route de TipaeruiImm Hachette Pacifique, Papeete",
        "BP 130, 98713 PAPEETE BP, Aéroport de Avatoru, Rangiroa",
        "BP 130, 98713 PAPEETE BP, 10, Av Bruat, Papeete",
        "BP 130, 98713 PAPEETE BP, PK 4.9, Arue",
        "BP 130, 98713 PAPEETE BP, PK 21,1, Paea"
      ].join(' | ')
    }
    subject { described_class.new(siret, procedure_id).to_params }

    it 'L\'entreprise contient bien les bons renseignements' do
      expect(subject).to be_a_instance_of(Hash)
      expect(subject[:siret]).to eq(siret)
      expect(subject[:naf]).to eq('6419Z | 5221Z')
      expect(subject[:libelle_naf]).to eq('Autres intermédiations monétaires | Services auxiliaires des transports terrestres')
      got = subject[:adresse].split(' | ')
      expected = adresse.split(' | ')
      got.zip(expected).filter { |a, b| a != b }.each { |a, b| puts "==>#{a.tr("\n", ' ')}\n!= #{b.tr("\n", ' ')}" }
      expect(subject[:adresse]).to eq(adresse)
      expect(subject[:numero_voie]).to eq('115 | 415 | 10')
      expect(subject[:nom_voie]).to eq("rue Dumont d'Urville | rue Tihoni Tefaatau | Boulevard Pomare | Av Bruat")
      expect(subject[:code_postal]).to eq('98713')
      expect(subject[:localite]).to eq('Papeete | Uturoa | Pirae | Punaauia | Mahina | Taiohae | Faaa | Fare | Atuona | Afaahiti | Paopao | Hakahau | Papara | Moerai | Nunue | Mataura | Rangiroa | Iripau | Arue | Paea')
      expect(subject[:entreprise_siren]).to eq('075390')
      expect(subject[:entreprise_siret_siege_social]).to eq('075390')
      expect(subject[:entreprise_raison_sociale]).to eq('BANQUE SOCREDO')
      expect(subject[:entreprise_forme_juridique]).to eq('Société Anonyme à Directoire (dont S.A.E.M.)')
      expect(subject[:entreprise_forme_juridique_code]).to eq('560')
      expect(subject[:entreprise_code_effectif_entreprise]).to eq('8')
      expect(subject[:entreprise_nom]).to eq('')
      expect(subject[:entreprise_prenom]).to eq('')
      expect(subject[:entreprise_numero_tva_intracommunautaire]).to eq('')
    end
  end

  context 'when siret is not found', vcr: { cassette_name: 'pf_api_entreprise_not_found' } do
    let(:bad_siret) { 111111 }
    subject { described_class.new(bad_siret, 12).to_params }

    it { expect(subject).to eq({}) }
  end
end
