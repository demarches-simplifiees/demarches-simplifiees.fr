describe Champs::HeaderSectionChamp do
  describe '#section_index' do
    let(:types_de_champ) do
      [
        build(:type_de_champ_header_section, position: 1),
        build(:type_de_champ_civilite,       position: 2),
        build(:type_de_champ_text,           position: 3),
        build(:type_de_champ_header_section, position: 4),
        build(:type_de_champ_email,          position: 5)
      ]
    end

    context 'for root-level champs' do
      let(:procedure) { create(:procedure, types_de_champ: types_de_champ) }
      let(:dossier) { create(:dossier, procedure: procedure) }
      let(:first_header)  { dossier.champs[0] }
      let(:second_header) { dossier.champs[3] }

      it 'returns the index of the section (starting from 1)' do
        expect(first_header.section_index).to eq '1'
        expect(second_header.section_index).to eq '2'
      end
    end

    context 'for repetition champs' do
      let(:procedure) { create(:procedure, types_de_champ: [build(:type_de_champ_repetition, types_de_champ: types_de_champ)]) }
      let(:dossier) { create(:dossier, procedure: procedure) }

      let(:first_header)  { dossier.champs.first.champs[0] }
      let(:second_header) { dossier.champs.first.champs[3] }

      it 'returns the index of the section in the repetition (starting from 1)' do
        expect(first_header.section_index).to eq '1'
        expect(second_header.section_index).to eq '2'
      end
    end

    let(:types_de_champ_with_levels) do
      [
        create(:type_de_champ_header_section, order_place: 1, level: 2), # 1
        create(:type_de_champ_header_section, order_place: 2, level: 3), # 1.1
        create(:type_de_champ_header_section, order_place: 3, level: 2), # 2
        create(:type_de_champ_header_section, order_place: 5, level: 1), # 1
        create(:type_de_champ_header_section, order_place: 6), # 2 (level 1 by default)
        create(:type_de_champ_header_section, order_place: 7, level: 2), # 2.1
        create(:type_de_champ_header_section, order_place: 8, level: 3), # 2.1.1
        create(:type_de_champ_header_section, order_place: 9, level: 3) # 2.1.2
      ]
    end

    context 'for root level champs with header levels' do
      let(:procedure) { create(:procedure, types_de_champ: types_de_champ_with_levels) }
      let(:dossier) { create(:dossier, procedure: procedure) }
      let(:ref) { dossier }

      it 'returns the index of the section (starting from 1)' do
        expect(ref.champs.map(&:section_index)).to eq(['1', '1.1', '2', '1', '2', '2.1', '2.1.1', '2.1.2'])
      end
    end
  end
end
