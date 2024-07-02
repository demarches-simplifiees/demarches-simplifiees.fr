describe EditableChamp::DatetimeComponent, type: :component do
  let(:component) {
    described_class.new(form: instance_double(ActionView::Helpers::FormBuilder, object_name: "dossier[champs_public_attributes]"), champ:)
  }

  describe '#formatted_value_for_datetime_locale' do
    # before { champ.validate(:prefill) }
    subject { component.formatted_value_for_datetime_locale }

    context 'when the value is nil' do
      let(:champ) { Champs::DatetimeChamp.new(value: nil, dossier: create(:dossier), type_de_champ: create(:type_de_champ_datetime)) }

      it { is_expected.to be_nil }
    end

    context 'when the value is not a valid datetime' do
      let(:champ) { Champs::DatetimeChamp.new(value: 'invalid', dossier: create(:dossier), type_de_champ: create(:type_de_champ_datetime)) }

      it { is_expected.to be_nil }
    end

    context 'when the value is a valid datetime' do
      let(:champ) { Champs::DatetimeChamp.new(value: '2020-01-01T00:00:00+01:00', dossier: create(:dossier), type_de_champ: create(:type_de_champ_datetime)) }

      it { is_expected.to eq('2020-01-01T00:00') }
    end
  end
end
