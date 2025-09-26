# frozen_string_literal: true

describe TreeService do
  describe '.tree' do
    let(:procedure) { create(:procedure, types_de_champ_public:) }
    let(:dossier) { create(:dossier, :en_construction, procedure:) }

    subject { described_class.new(dossier).tree }

    context 'with a champ' do
      let(:types_de_champ_public) { [{ type: :text }] }

      it { expect(subject.map(&:type)).to eq(["Champs::TextChamp"]) }
    end

    context 'with a empty header section' do
      let(:types_de_champ_public) { [{ type: :header_section }] }

      it { expect(subject.map(&:type)).to eq(["Champs::HeaderSectionChamp"]) }
    end

    context 'with a header section and a champ' do
      let(:types_de_champ_public) { [{ type: :header_section }, { type: :text }] }
      let(:header_section) { subject.first }

      it { expect(subject.map(&:type)).to eq(["Champs::HeaderSectionChamp"]) }
      it { expect(header_section.children.map(&:type)).to eq(["Champs::TextChamp"]) }
    end

    context 'with a header section and a nested header section and a champ' do
      let(:types_de_champ_public) { [{ type: :header_section }, { type: :header_section, level: 2 }, { type: :text }] }
      let(:header_section) { subject.first }
      let(:nested_header_section) { header_section.children.first }

      it { expect(subject.map(&:type)).to eq(["Champs::HeaderSectionChamp"]) }
      it { expect(header_section.children.map(&:type)).to eq(["Champs::HeaderSectionChamp"]) }
      it { expect(nested_header_section.children.map(&:type)).to eq(["Champs::TextChamp"]) }
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

      it { expect(subject.map(&:libelle)).to eq(["h1"]) }
      it { expect(header_section.children.map(&:libelle)).to eq(["repetition"]) }
      it { expect(repetition.new_rows.first.children.map(&:libelle)).to eq(["nested h1", "another nested h1"]) }
    end
  end
end
