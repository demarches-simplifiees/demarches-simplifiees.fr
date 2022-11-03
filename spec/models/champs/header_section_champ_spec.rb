describe Champs::HeaderSectionChamp do
  describe '#section_index' do
    let(:types_de_champ) do
      [
        { type: :header_section },
        { type: :civilite },
        { type: :text },
        { type: :header_section },
        { type: :email }
      ]
    end
    let(:types_de_champ_public) { types_de_champ }
    let(:procedure) { create(:procedure, types_de_champ_public: types_de_champ_public) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    context 'for root-level champs' do
      let(:first_header)  { dossier.champs.first }
      let(:second_header) { dossier.champs.fourth }

      it 'returns the index of the section (starting from 1)' do
        expect(first_header.section_index).to eq '1'
        expect(second_header.section_index).to eq '2'
      end
    end

    context 'for repetition champs' do
      let(:types_de_champ_public) { [{ type: :repetition, children: types_de_champ }] }

      let(:first_header)  { dossier.champs.first.champs.first }
      let(:second_header) { dossier.champs.first.champs.fourth }

      it 'returns the index of the section in the repetition (starting from 1)' do
        expect(first_header.section_index).to eq '1'
        expect(second_header.section_index).to eq '2'
      end
    end

    let(:types_de_champ_with_levels) do
      [
        { type: :header_section, position: 1, level: 2 }, # 1
        { type: :header_section, position: 2, level: 3 }, # 1.1
        { type: :header_section, position: 3, level: 2 }, # 2
        { type: :header_section, position: 5, level: 1 }, # 1
        { type: :header_section, position: 6 }, # 2 (level 1 by default)
        { type: :header_section, position: 7, level: 2 }, # 2.1
        { type: :header_section, position: 8, level: 3 }, # 2.1.1
        { type: :header_section, position: 9, level: 3 } # 2.1.2
      ]
    end

    context 'for root level champs with header levels' do
      let(:procedure) { create(:procedure, types_de_champ_public: types_de_champ_with_levels) }
      let(:dossier) { create(:dossier, procedure: procedure) }
      let(:ref) { dossier }

      it 'returns the index of the section (starting from 1)' do
        expect(ref.champs.map(&:section_index)).to eq(['1', '1.1', '2', '1', '2', '2.1', '2.1.1', '2.1.2'])
      end
    end
  end
end
