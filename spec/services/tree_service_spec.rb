# frozen_string_literal: true

describe TreeService do
  describe '.tree' do
    subject(:tree) { described_class.new(dossier).tree }

    let(:procedure) { create(:procedure, types_de_champ_public:) }
    let(:dossier) { create(:dossier, :en_construction, procedure:) }

    context 'with a nested structure' do
      let(:types_de_champ_public) do
        [
          { type: :text, libelle: 'text' },
          { type: :header_section, level: 1, libelle: 'h1' },
          {
            type: :repetition,
            libelle: 'repetition',
            children: [
              { type: :header_section, level: 1, libelle: 'nested h1' },
              { type: :header_section, level: 2, libelle: 'nested h2' },
              { type: :text, libelle: 'nested text' },
              { type: :header_section, level: 1, libelle: 'another nested h1' }
            ]
          }
        ]
      end
      let(:header_section) { tree.second }
      let(:repetition) { header_section.children.first }
      let(:first_row) { repetition.new_rows.first }
      let(:nested_h1) { first_row.children.first }
      let(:nested_h2) { nested_h1.children.first }

      it do
        expect(tree.map(&:libelle)).to eq(["text", "h1"])
        expect(header_section.children.map(&:libelle)).to eq(["repetition"])
        expect(repetition.new_rows.first.children.map(&:libelle)).to eq(["nested h1", "another nested h1"])
        expect(nested_h2.libelle).to eq("nested h2")
        expect(nested_h2.children.map(&:libelle)).to eq(["nested text"])

        expect(nested_h2.parent).to eq(nested_h1)
        expect(nested_h1.parent).to eq(first_row)
        expect(first_row.parent).to eq(repetition)
        expect(repetition.parent).to eq(header_section)
        expect(header_section.parent).to be_nil
      end
    end
  end
end
