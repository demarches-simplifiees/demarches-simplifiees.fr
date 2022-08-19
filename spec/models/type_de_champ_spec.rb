describe TypeDeChamp do
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
        let(:template_double) { double('template', attached?: attached, purge_later: true, blob: double(byte_size: 10, content_type: 'text/plain')) }
        let(:tdc) { create(:type_de_champ_piece_justificative) }

        subject { template_double }

        before do
          allow(tdc).to receive(:piece_justificative_template).and_return(template_double)

          tdc.update(type_champ: target_type_champ)
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
      let!(:procedure) { create(:procedure) }
      let(:tdc) { create(:type_de_champ_repetition, :with_types_de_champ, procedure: procedure) }

      before do
        tdc.update(type_champ: target_type_champ)
      end

      context 'when the target type_champ is not repetition' do
        let(:target_type_champ) { TypeDeChamp.type_champs.fetch(:text) }

        it 'removes the children types de champ' do
          expect(procedure.draft_revision.children_of(tdc)).to be_empty
        end
      end
    end

    describe 'changing the type_champ from a drop_down_list' do
      let(:tdc) { create(:type_de_champ_drop_down_list) }

      before do
        tdc.update(type_champ: target_type_champ)
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

  describe '#public_only' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }

    it 'partition public and private' do
      expect(procedure.types_de_champ.count).to eq(1)
      expect(procedure.types_de_champ_private.count).to eq(1)
    end
  end

  describe 'condition' do
    let(:type_de_champ) { create(:type_de_champ) }
    let(:condition) { Logic::Eq.new(Logic::Constant.new(true), Logic::Constant.new(true)) }

    it 'saves and reload the condition' do
      type_de_champ.update(condition: condition)
      type_de_champ.reload
      expect(type_de_champ.condition).to eq(condition)
    end
  end
end
