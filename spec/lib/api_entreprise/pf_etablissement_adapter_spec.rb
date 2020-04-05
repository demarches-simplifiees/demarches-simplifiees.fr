require 'spec_helper'

describe ApiEntreprise::PfEtablissementAdapter do
  let(:procedure_id) { 33 }

  context 'Numéro TAHITI valide', vcr: { cassette_name: 'pf_api_entreprise' } do
    let(:siret) { '075390' }
    let!(:adresse) {
      [
        "BP 130, 98713 PAPEETE BP,\n115,\nrue Dumont d'Urville,\nquartier Orovini,\nPapeete",
        "BP 130, 98713 PAPEETE BP,\nCentre villeRaiatea,\nUturoa",
        "BP 130, 98713 PAPEETE BP,\nrue Tihoni Tefaatau,\nimmeuble SCI Taaone,\nRue Tihoni TefaatauImm SCI Taaone,\nPirae",
        "BP 130, 98713 PAPEETE BP,\nLotissement zone industrielle de PunaruuLot A,\nPunaauia",
        "BP 130, 98713 PAPEETE BP,\nRoute de la pointe VénusDomaine Fritch,\nMahina",
        "BP 130, 98713 PAPEETE BP,\nTerre domanialeNuku Hiva,\nTaiohae",
        "BP 130, 98713 PAPEETE BP,\nHall du rez-de-chaussée de l'aéroport,\nFaaa",
        "BP 130, 98713 PAPEETE BP,\n415,\nBoulevard Pomare,\nimmeuble Vaiete,\n415 Boulevard PomareImm Vaiete,\nPapeete",
        "BP 130, 98713 PAPEETE BP,\nLots 1 et 2 de la Terre FareoaHuahine,\nFare",
        "BP 130, 98713 PAPEETE BP,\nTerre Mataupuna n°2479Hiva Oa,\nAtuona",
        "BP 130, 98713 PAPEETE BP,\nCentre commercial Temahame Nui de Taravao,\nAfaahiti",
        "BP 130, 98713 PAPEETE BP,\nCentre commercial de MaharepaQrt Orovau,\nPaopao",
        "BP 130, 98713 PAPEETE BP,\nFare UteImm Le Cail,\nPapeete",
        "BP 130, 98713 PAPEETE BP,\nCentre communal de Ua Pou,\nHakahau",
        "BP 130, 98713 PAPEETE BP,\nPk 36Centre commercial de Apatea,\nPapara",
        "BP 130, 98713 PAPEETE BP,\nTerre Onanae 6Rurutu,\nMoerai",
        "BP 130, 98713 PAPEETE BP,\nTerre Taamotu 1,\nNunue",
        "BP 130, 98713 PAPEETE BP,\nComplexe municipalTubuai,\nMataura",
        "BP 130, 98713 PAPEETE BP,\nBoulevard Pomare,\nquartier du Commerce,\nBoulevard PomareQuartier du Commerce,\nPapeete",
        "BP 130, 98713 PAPEETE BP,\nLot communal de Tiputa,\nRangiroa",
        "BP 130, 98713 PAPEETE BP,\nRte de l'ancienne mairieFace centre tavararo - Terre Tehorua 2 parcelle A,\nFaaa",
        "BP 130, 98713 PAPEETE BP,\nRue Dumont d'Urville(Parking),\nPapeete",
        "BP 130, 98713 PAPEETE BP,\nPatio - Terre MainanuiTahaa,\nIripau",
        "BP 130, 98713 PAPEETE BP,\nRoute de TipaeruiImm Hachette Pacifique,\nPapeete",
        "BP 130, 98713 PAPEETE BP,\nAéroport de Avatoru,\nRangiroa",
        "BP 130, 98713 PAPEETE BP,\n10,\nAv Bruat,\n10 Av Bruat,\nPapeete",
        "BP 130, 98713 PAPEETE BP,\nPK 4.9,\nPk 4.9 c/mont,\nArue",
        "BP 130, 98713 PAPEETE BP,\nPK 21,1,\nPaea"
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
    end
  end

  context 'when siret is not found', vcr: { cassette_name: 'pf_api_entreprise_not_found' } do
    let(:bad_siret) { 111111 }
    subject { described_class.new(bad_siret, 12).to_params }

    it { expect(subject).to eq({}) }
  end
end
