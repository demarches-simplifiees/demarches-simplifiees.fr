describe EditableChamp::DatetimeComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :datetime, stable_id: 99 }]) }
  let(:dossier) { create(:dossier, procedure:) }

  let(:component) {
    described_class.new(form: instance_double(ActionView::Helpers::FormBuilder, object_name: "dossier[champs_public_attributes]"), champ:)
  }

  describe '#formatted_value_for_datetime_locale' do
    # before { champ.validate(:prefill) }
    subject { component.formatted_value_for_datetime_locale }

    context 'when the value is nil' do
      let(:champ) { Champs::DatetimeChamp.new(value: nil, dossier:, stable_id: 99) }

      it { is_expected.to be_nil }
    end

    context 'when the value is not a valid datetime' do
      let(:champ) { Champs::DatetimeChamp.new(value: 'invalid', dossier:, stable_id: 99) }

      it { is_expected.to be_nil }
    end

    context 'when the value is a valid datetime' do
      let(:champ) { Champs::DatetimeChamp.new(value: '2020-01-01T00:00:00+01:00', dossier:, stable_id: 99) }

      it { is_expected.to eq('2020-01-01T00:00') }
    end
  end
end
