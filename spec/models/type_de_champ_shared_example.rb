shared_examples 'type_de_champ_spec' do
  describe 'validation' do
    context 'libelle' do
      it { is_expected.not_to allow_value(nil).for(:libelle) }
      it { is_expected.not_to allow_value('').for(:libelle) }
      it { is_expected.to allow_value('Montant projet').for(:libelle) }
    end

    context 'type' do
      it { is_expected.not_to allow_value(nil).for(:type_champ) }
      it { is_expected.not_to allow_value('').for(:type_champ) }

      it { is_expected.to allow_value('text').for(:type_champ) }
      it { is_expected.to allow_value('textarea').for(:type_champ) }
      it { is_expected.to allow_value('datetime').for(:type_champ) }
      it { is_expected.to allow_value('number').for(:type_champ) }
      it { is_expected.to allow_value('checkbox').for(:type_champ) }
    end

    context 'order_place' do
      # it { is_expected.not_to allow_value(nil).for(:order_place) }
      # it { is_expected.not_to allow_value('').for(:order_place) }
      it { is_expected.to allow_value(1).for(:order_place) }
    end

    context 'description' do
      it { is_expected.to allow_value(nil).for(:description) }
      it { is_expected.to allow_value('').for(:description) }
      it { is_expected.to allow_value('blabla').for(:description) }
    end
  end

  describe 'field_for_list?' do
    let(:type_de_champ_yes) { create :type_de_champ_public, type_champ: 'text' }
    let(:type_de_champ_no_1) { create :type_de_champ_public, type_champ: 'textarea' }
    let(:type_de_champ_no_2) { create :type_de_champ_public, type_champ: 'header_section' }

    it { expect(type_de_champ_yes.field_for_list?).to be_truthy }
    it { expect(type_de_champ_no_1.field_for_list?).to be_falsey }
    it { expect(type_de_champ_no_2.field_for_list?).to be_falsey }
  end
end
