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
        expect(first_header.section_index).to eq 1
        expect(second_header.section_index).to eq 2
      end
    end

    context 'for repetition champs' do
      let(:procedure) { create(:procedure, types_de_champ: [build(:type_de_champ_repetition, types_de_champ: types_de_champ)]) }
      let(:dossier) { create(:dossier, procedure: procedure) }

      let(:first_header)  { dossier.champs.first.champs[0] }
      let(:second_header) { dossier.champs.first.champs[3] }

      it 'returns the index of the section in the repetition (starting from 1)' do
        expect(first_header.section_index).to eq 1
        expect(second_header.section_index).to eq 2
      end
    end
  end
end
