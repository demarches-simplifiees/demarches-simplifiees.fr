# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillAnnuaireEducationTypeDeChamp do
  let(:procedure) { create(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_annuaire_education, procedure: procedure) }

  describe 'ancestors' do
    subject { described_class.new(type_de_champ, procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#to_assignable_attributes' do
    let(:champ) { create(:champ_annuaire_education, type_de_champ: type_de_champ) }
    subject { described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value) }

    context 'when the value is nil' do
      let(:value) { nil }
      it { is_expected.to eq(nil) }
    end

    context 'when the value is empty' do
      let(:value) { '' }
      it { is_expected.to eq(nil) }
    end

    context 'when the value is present' do
      let(:value) { '0050009H' }
      it { is_expected.to match({ id: champ.id, external_id: '0050009H', value: '0050009H' }) }
    end
  end
end
