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

    context 'changing the type_champ from a piece_justificative' do
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

    describe 'changing the type_champ from a repetition' do
      let(:tdc) { create(:type_de_champ_repetition, :with_types_de_champ) }

      before do
        tdc.update_attribute('type_champ', target_type_champ)
      end

      context 'when the target type_champ is not repetition' do
        let(:target_type_champ) { TypeDeChamp.type_champs.fetch(:text) }

        it 'removes the children types de champ' do
          expect(tdc.types_de_champ).to be_empty
        end
      end
    end

    describe 'changing the type_champ from a drop_down_list' do
      let(:tdc) { create(:type_de_champ_drop_down_list) }

      before do
        tdc.update_attribute('type_champ', target_type_champ)
      end

      context 'when the target type_champ is not drop_down_list' do
        let(:target_type_champ) { TypeDeChamp.type_champs.fetch(:text) }

        it { expect(tdc.drop_down_options).to be_nil }
      end

      context 'when the target type_champ is linked_drop_down_list' do
        let(:target_type_champ) { TypeDeChamp.type_champs.fetch(:linked_drop_down_list) }

        it { expect(tdc.drop_down_options).to be_present }
      end

      context 'when the target type_champ is multiple_drop_down_list' do
        let(:target_type_champ) { TypeDeChamp.type_champs.fetch(:multiple_drop_down_list) }

        it { expect(tdc.drop_down_options).to be_present }
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
    let(:type_de_champ_text) { create(:type_de_champ_text, procedure: procedure) }
    let(:type_de_champ_integer_number_attrs) { attributes_for(:type_de_champ_integer_number) }

    it "associates nested types_de_champ to the parent procedure" do
      expect(type_de_champ.types_de_champ.size).to eq(0)
      expect(procedure.types_de_champ.size).to eq(1)

      procedure.update!(types_de_champ_attributes: [
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

  describe "linked_drop_down_list" do
    let(:type_de_champ) { create(:type_de_champ_linked_drop_down_list) }

    it 'should validate without label' do
      type_de_champ.drop_down_list_value = 'toto'
      expect(type_de_champ.validate).to be_falsey
      messages = type_de_champ.errors.full_messages
      expect(messages.size).to eq(1)
      expect(messages.first.starts_with?("#{type_de_champ.libelle} doit commencer par")).to be_truthy

      type_de_champ.libelle = ''
      expect(type_de_champ.validate).to be_falsey
      messages = type_de_champ.errors.full_messages
      expect(messages.size).to eq(2)
      expect(messages.last.starts_with?("La liste doit commencer par")).to be_truthy
    end
  end

  describe '#type_de_champ_types_for' do
    let(:procedure) { create(:procedure) }
    let(:user) { create(:user) }

    context 'when procedure without legacy "number"' do
      it 'should have "nombre decimal" instead of "nombre"' do
        expect(TypeDeChamp.type_de_champ_types_for(procedure, user).find { |tdc| tdc.last == TypeDeChamp.type_champs.fetch(:number) }).to be_nil
        expect(TypeDeChamp.type_de_champ_types_for(procedure, user).find { |tdc| tdc.last == TypeDeChamp.type_champs.fetch(:decimal_number) }).not_to be_nil
      end
    end

    context 'when procedure with legacy "number"' do
      let(:procedure) { create(:procedure, :with_number) }

      it 'should have "nombre decimal" and "nombre"' do
        expect(TypeDeChamp.type_de_champ_types_for(procedure, user).find { |tdc| tdc.last == TypeDeChamp.type_champs.fetch(:number) }).not_to be_nil
        expect(TypeDeChamp.type_de_champ_types_for(procedure, user).find { |tdc| tdc.last == TypeDeChamp.type_champs.fetch(:decimal_number) }).not_to be_nil
      end
    end
  end

  describe '#drop_down_list_options' do
    let(:value) do
      <<~EOS
        Cohésion sociale
        Dév.Eco / Emploi
        Cadre de vie / Urb.
        Pilotage / Ingénierie
      EOS
    end
    let(:type_de_champ) { create(:type_de_champ_drop_down_list, drop_down_list_value: value) }

    it { expect(type_de_champ.drop_down_list_options).to eq ['', 'Cohésion sociale', 'Dév.Eco / Emploi', 'Cadre de vie / Urb.', 'Pilotage / Ingénierie'] }

    context 'when one value is empty' do
      let(:value) do
        <<~EOS
          Cohésion sociale
          Cadre de vie / Urb.
          Pilotage / Ingénierie
        EOS
      end

      it { expect(type_de_champ.drop_down_list_options).to eq ['', 'Cohésion sociale', 'Cadre de vie / Urb.', 'Pilotage / Ingénierie'] }
    end
  end

  describe 'disabled_options' do
    let(:value) do
      <<~EOS
        tip
        --top--
        --troupt--
        ouaich
      EOS
    end
    let(:type_de_champ) { create(:type_de_champ_drop_down_list, drop_down_list_value: value) }

    it { expect(type_de_champ.drop_down_list_disabled_options).to match(['--top--', '--troupt--']) }
  end
end
