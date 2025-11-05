# frozen_string_literal: true

RSpec.describe Dossiers::AnnuaireEducationComponent, type: :component do
  let(:champ) { double('Champ', data: annuaire_data) }

  let(:annuaire_data) do
    {
      'nom_etablissement' => 'Lycée Jean Moulin',
      'identifiant_de_l_etablissement' => '0123456A',
      'siren_siret' => '12345678901234',
      'nom_commune' => 'Paris',
      'code_commune' => '75001',
      'libelle_academie' => 'Paris',
      'code_academie' => '01',
      'libelle_nature' => 'Lycée général',
      'code_nature' => 'LGT',
      'type_contrat_prive' => 'SANS OBJET',
      'nombre_d_eleves' => '450',
      'adresse_1' => '123 rue de la République',
      'code_postal' => '75001',
      'libelle_region' => 'Île-de-France',
      'code_region' => '11',
      'telephone' => '0145123456',
      'mail' => 'contact@lycee-moulin.fr',
      'web' => 'https://lycee-moulin.fr',
    }
  end

  subject { render_inline(described_class.new(champ:)) }

  before do
    allow(Dossiers::ExternalChampComponent).to receive(:new).and_call_original
    subject
  end

  describe '#call' do
    it 'renders ExternalChampComponent with correct arguments' do
      expect(Dossiers::ExternalChampComponent).to have_received(:new) do |data:, details:, source:|
        expected_data = [
          ["Nom de l’établissement", "Lycée Jean Moulin"],
          ["L’identifiant de l’etablissement", "0123456A"],
          ["SIREN/SIRET", "12345678901234"]
        ]

        expected_details = [
          ["Commune", "Paris (75001)"],
          ["Académie", "Paris (01)"],
          ["Nature de l’établissement", "Lycée général (LGT)"],
          ["Type de contrat privé", nil],
          ["Nombre d’élèves", "450"],
          ["Adresse", "123 rue de la République<br>75001 Paris<br>Île-de-France (11)"],
          ["Téléphone", "0145123456"],
          ["Email", "contact@lycee-moulin.fr"],
          ["Site internet", "https://lycee-moulin.fr"]
        ]

        expected_source = "Annuaire de l’Éducation Nationale"

        expect(data).to eq(expected_data)
        expect(details).to eq(expected_details)
        expect(source).to eq(expected_source)
      end
    end

    context 'when the code commune is missing and type_de_contrat is not sans objet' do
      let(:annuaire_data) do
        super().merge({ 'code_commune' => nil, 'type_contrat_prive' => 'SOUS CONTRAT' })
      end

      it do
        expect(Dossiers::ExternalChampComponent).to have_received(:new) do |args|
          details = args[:details]
          expect(details.find { |label, _| label == 'Commune' }[1]).to eq('Paris')
          expect(details.find { |label, _| label == 'Type de contrat privé' }[1]).to eq('SOUS CONTRAT')
        end
      end
    end

    context 'when the nom_commune is missing' do
      let(:annuaire_data) { super().merge({ 'nom_commune' => nil }) }

      it do
        expect(Dossiers::ExternalChampComponent).to have_received(:new) do |args|
          details = args[:details]
          expect(details.find { |label, _| label == 'Commune' }[1]).to eq('Non renseignée')
        end
      end
    end
  end
end
