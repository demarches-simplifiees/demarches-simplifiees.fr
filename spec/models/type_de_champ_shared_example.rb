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

      it do
        TypeDeChamp.type_champs.each do |(type_champ, _)|
          type_de_champ = create(:"type_de_champ_#{type_champ}")
          champ = type_de_champ.champ.create

          expect(type_de_champ.class.name).to match(/^TypesDeChamp::/)
          expect(champ.class.name).to match(/^Champs::/)
        end
      end
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
end
