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

      it { is_expected.to allow_value(TypeDeChamp.type_champs.fetch(:text)).for(:type_champ) }
      it { is_expected.to allow_value(TypeDeChamp.type_champs.fetch(:textarea)).for(:type_champ) }
      it { is_expected.to allow_value(TypeDeChamp.type_champs.fetch(:datetime)).for(:type_champ) }
      it { is_expected.to allow_value(TypeDeChamp.type_champs.fetch(:number)).for(:type_champ) }
      it { is_expected.to allow_value(TypeDeChamp.type_champs.fetch(:checkbox)).for(:type_champ) }

      it do
        TypeDeChamp.type_champs.each do |(type_champ, _)|
          type_de_champ = create(:"type_de_champ_#{type_champ}")
          champ = type_de_champ.champ.create

          expect(type_de_champ.dynamic_type.class.name).to match(/^TypesDeChamp::/)
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

    context 'remove piece_justificative_template' do
      context 'when the tdc is piece_justificative' do
        let(:template_double) { double('template', attached?: attached, purge_later: true) }
        let(:tdc) { create(:type_de_champ_piece_justificative) }

        subject { template_double }

        before do
          allow(tdc).to receive(:piece_justificative_template).and_return(template_double)

          tdc.update_attribute('type_champ', target_type_champ)
        end

        context 'when the target type_champ is not pj' do
          let(:target_type_champ) { TypeDeChamp.type_champs.fetch(:text) }

          context 'calls template.purge_later when a file is attached' do
            let(:attached) { true }

            it { is_expected.to have_received(:purge_later) }
          end

          context 'does not call template.purge_later when no file is attached' do
            let(:attached) { false }

            it { is_expected.not_to have_received(:purge_later) }
          end
        end

        context 'when the target type_champ is pj' do
          let(:target_type_champ) { TypeDeChamp.type_champs.fetch(:piece_justificative) }

          context 'does not call template.purge_later when a file is attached' do
            let(:attached) { true }

            it { is_expected.not_to have_received(:purge_later) }
          end
        end
      end
    end

    context 'delegate validation to dynamic type' do
      subject { build(:type_de_champ_text) }
      let(:dynamic_type) do
        Class.new(TypesDeChamp::TypeDeChampBase) do
          validate :never_valid

          def never_valid
            errors.add(:troll, 'always invalid')
          end
        end.new(subject)
      end

      before { subject.instance_variable_set(:@dynamic_type, dynamic_type) }

      it { is_expected.to be_invalid }
      it do
        subject.validate
        expect(subject.errors.full_messages.to_sentence).to eq('Troll always invalid')
      end
    end
  end
end
