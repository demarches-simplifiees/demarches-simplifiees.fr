# frozen_string_literal: true

describe DossierProjectionService do
  describe '#project' do
    subject { described_class.project(dossiers_ids, columns) }

    let(:procedure) { create(:procedure, types_de_champ_public:) }
    let(:types_de_champ_public) do
      [
        { type: :text, libelle: 'texte' },
        { type: :integer_number, libelle: 'nombre entier' },
      ]
    end
    let(:dossiers) { create_list(:dossier, 3, procedure:) }
    let(:dossiers_ids) { dossiers.take(2).map(&:id) }
    let(:text_column) { procedure.find_column(label: 'texte') }
    let(:columns) { [text_column] }

    it do
      dossiers = subject

      expect(dossiers.size).to eq(2)

      # only load the champs required for the columns
      expect(dossiers.first.champs.size).to eq(1)
    end
  end
end
