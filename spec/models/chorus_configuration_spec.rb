# frozen_string_literal: true

describe ChorusConfiguration do
  context 'empty' do
    subject { create(:procedure, :empty_chorus) }
    it { is_expected.to be_valid }
  end

  context 'partially filled chorus_configuration' do
    subject { create(:procedure, :partial_chorus) }
    it { is_expected.to be_valid }
  end

  context 'fully filled chorus_configuration' do
    subject { create(:procedure, :filled_chorus) }
    it { is_expected.to be_valid }
  end

  describe 'ChorusConfiguration' do
    it 'works without args' do
      expect { ChorusConfiguration.new }.not_to raise_error
    end

    it 'works with args' do
      expect { ChorusConfiguration.new({}) }.not_to raise_error
    end

    it 'works with existing args' do
      expect do
        cc = ChorusConfiguration.new()
        cc.assign_attributes(centre_de_cout: {}, domaine_fonctionnel: {}, referentiel_de_programmation: {})
      end.not_to raise_error
    end
  end

  describe '#complete?' do
    subject { procedure.chorus_configuration.complete? }

    context 'without data' do
      let(:procedure) { create(:procedure, :empty_chorus) }
      it { is_expected.to be_falsey }
    end

    context 'with partial data' do
      let(:procedure) { create(:procedure, :partial_chorus) }
      it { is_expected.to be_falsey }
    end

    context 'with all data' do
      let(:procedure) { create(:procedure, :filled_chorus) }
      it { is_expected.to be_truthy }
    end
  end
end
