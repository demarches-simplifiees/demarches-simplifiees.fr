describe Champs::EmailChamp do
  subject { build(:champ_email, value: value).tap(&:valid?) }

  describe '#valid?' do
    context 'when the value is an email' do
      let(:value) { 'jean@dupont.fr' }

      it { is_expected.to be_valid }
    end

    context 'when the value is not an email' do
      let(:value) { 'jean@' }

      it { is_expected.to_not be_valid }
    end

    context 'when the value is blank' do
      let(:value) { '' }

      it { is_expected.to_not be_valid }
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it { is_expected.to be_valid }
    end
  end
end
