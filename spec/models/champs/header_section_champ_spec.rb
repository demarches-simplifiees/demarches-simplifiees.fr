describe Champs::HeaderSectionChamp do
  describe '#section_index' do
    let(:types_de_champ) do
      [
        create(:type_de_champ_header_section, position: 1, procedure: procedure),
        create(:type_de_champ_civilite,       position: 2, procedure: procedure),
        create(:type_de_champ_text,           position: 3, procedure: procedure),
        create(:type_de_champ_header_section, position: 4, procedure: procedure),
        create(:type_de_champ_email,          position: 5, procedure: procedure)
      ]
    end

    context 'for root-level champs' do
      let(:procedure) { create(:procedure) }
      let(:dossier) { create(:dossier, procedure: procedure) }
      let(:first_header)  { dossier.champs[0] }
      let(:second_header) { dossier.champs[3] }

      before { types_de_champ }

      it 'returns the index of the section (starting from 1)' do
        expect(first_header.section_index).to eq 1
        expect(second_header.section_index).to eq 2
      end
    end

    context 'for repetition champs' do
      let(:procedure) { create(:procedure, :with_repetition) }
      let(:dossier) { create(:dossier, procedure: procedure) }

      let(:repetition_tdc)  { procedure.current_revision.types_de_champ.find(&:repetition?) }
      let(:first_header)  { dossier.champs.first.champs[0] }
      let(:second_header) { dossier.champs.first.champs[3] }

      before do
        repetition_tdc.types_de_champ = types_de_champ
      end

      it 'returns the index of the section in the repetition (starting from 1)' do
        expect(first_header.section_index).to eq 1
        expect(second_header.section_index).to eq 2
      end
    end
  end
end
