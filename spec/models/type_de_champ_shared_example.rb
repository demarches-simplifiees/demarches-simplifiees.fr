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

    context 'stable_id' do
      it {
        type_de_champ = create(:type_de_champ_text)
        expect(type_de_champ.id).to eq(type_de_champ.stable_id)
        cloned_type_de_champ = type_de_champ.clone
        expect(cloned_type_de_champ.stable_id).to eq(type_de_champ.stable_id)
      }
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

  describe "repetition" do
    let(:procedure) { create(:procedure) }
    let(:type_de_champ) { create(:type_de_champ_repetition, procedure: procedure) }
    let(:type_de_champ_text) { create(:type_de_champ_text) }
    let(:type_de_champ_integer_number_attrs) { attributes_for(:type_de_champ_integer_number) }

    it "associates nested types_de_champ to the parent procedure" do
      expect(type_de_champ.types_de_champ.size).to eq(0)
      expect(procedure.types_de_champ.size).to eq(1)

      procedure.update(types_de_champ_attributes: [
        {
          id: type_de_champ.id,
          libelle: type_de_champ.libelle,
          types_de_champ_attributes: [type_de_champ_integer_number_attrs]
        }
      ])
      procedure.reload
      type_de_champ.reload

      expect(procedure.types_de_champ.size).to eq(1)
      expect(type_de_champ.types_de_champ.size).to eq(1)

      expect(type_de_champ.types_de_champ.first.parent).to eq(type_de_champ)
      expect(type_de_champ.types_de_champ.first.procedure).to eq(procedure)
      expect(type_de_champ.types_de_champ.first.private?).to eq(false)

      type_de_champ.types_de_champ << type_de_champ_text
      expect(type_de_champ.types_de_champ.size).to eq(2)
      expect(type_de_champ_text.parent).to eq(type_de_champ)

      admin = create(:administrateur)
      cloned_procedure = procedure.clone(admin, false)

      expect(cloned_procedure.types_de_champ.first.types_de_champ).not_to be_empty
    end
  end
end
