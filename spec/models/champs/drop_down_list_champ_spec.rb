describe Champs::DropDownListChamp do
  describe '#drop_down_other?' do
    let(:drop_down) { create(:champ_drop_down_list) }

    context 'when drop_down_other is nil' do
      it do
        drop_down.type_de_champ.drop_down_other = nil
        expect(drop_down.drop_down_other?).to be false

        drop_down.type_de_champ.drop_down_other = "0"
        expect(drop_down.drop_down_other?).to be false

        drop_down.type_de_champ.drop_down_other = false
        expect(drop_down.drop_down_other?).to be false

        drop_down.type_de_champ.drop_down_other = "1"
        expect(drop_down.drop_down_other?).to be true

        drop_down.type_de_champ.drop_down_other = true
        expect(drop_down.drop_down_other?).to be true
      end
    end
  end
end
