# frozen_string_literal: true

describe TreeService do
  describe '.tree' do
    let(:procedure) { create(:procedure, types_de_champ_public:) }
    let(:dossier) { create(:dossier, :en_construction, procedure:) }

    subject { described_class.new(dossier).tree }

    context 'with a champ' do
      let(:types_de_champ_public) { [{ type: :text, libelle: 'text' }] }

      it { expect(subject.map(&:libelle)).to eq(["text"]) }
    end

    context 'with a empty header section' do
      let(:types_de_champ_public) { [{ type: :header_section, libelle: 'h1' }] }

      it { expect(subject.map(&:libelle)).to eq(["h1"]) }
    end

    context 'with a header section and a champ' do
      let(:types_de_champ_public) do
        [
          { type: :header_section, libelle: 'h1' },
          { type: :text, libelle: 'text' }
        ]
      end
      let(:header_section) { subject.first }
      let(:text) { header_section.children.first }

      it do
        expect(subject.map(&:libelle)).to eq(["h1"])
        expect(header_section.children.map(&:libelle)).to eq(["text"])
        expect(text.parent).to eq(header_section)
      end
    end

    context 'with a header section and a nested header section and a champ' do
      let(:types_de_champ_public) do
        [
          { type: :header_section, libelle: 'h1' },
          { type: :header_section, libelle: 'h2', level: 2 },
          { type: :text, libelle: 'text' }
        ]
      end
      let(:header_section) { subject.first }
      let(:nested_header_section) { header_section.children.first }

      it do
        expect(subject.map(&:libelle)).to eq(["h1"])
        expect(header_section.children.map(&:libelle)).to eq(["h2"])
        expect(nested_header_section.children.map(&:libelle)).to eq(["text"])
      end
    end

    context 'with nested section and repetition' do
      let(:types_de_champ_public) do
        [
          { type: :header_section, level: 1, libelle: 'h1' },
          {
            type: :repetition,
            libelle: 'repetition',
            children: [
              { type: :header_section, level: 1, libelle: 'nested h1' },
              { type: :header_section, level: 2, libelle: 'nested h2' },
              { type: :header_section, level: 1, libelle: 'another nested h1' }
            ]
          }
        ]
      end
      let(:header_section) { subject.first }
      let(:repetition) { header_section.children.first }
      let(:first_row) { repetition.new_rows.first }
      let(:nested_h1) { first_row.children.first }
      let(:nested_h2) { nested_h1.children.first }

      it do
        expect(subject.map(&:libelle)).to eq(["h1"])
        expect(header_section.children.map(&:libelle)).to eq(["repetition"])
        expect(repetition.new_rows.first.children.map(&:libelle)).to eq(["nested h1", "another nested h1"])
        expect(nested_h2.libelle).to eq("nested h2")

        expect(nested_h2.parent).to eq(nested_h1)
        expect(nested_h1.parent).to eq(first_row)
        expect(first_row.parent).to eq(repetition)
        expect(repetition.parent).to eq(header_section)
        expect(header_section.parent).to be_nil
      end
    end
  end
end
