describe Champs::EmailChamp do
  describe 'validation' do
    let(:now) { Time.zone.now }
    let(:before) { now + 1.day }
    let(:after) { now + 1.day }
    subject { build(:champ_email, value: value).valid?(:validate_champ_value) }

    context 'when value is username' do
      let(:value) { 'username' }
      # what we allowed but it was a mistake
      it { is_expected.to be_truthy }
    end

    context 'when value does not contain extension' do
      let(:value) { 'username@mailserver' }
      # what we allowed but it was a mistake
      it { is_expected.to be_truthy }
    end

    context 'when value include an alias' do
      let(:value) { 'username+alias@mailserver.fr' }
      it { is_expected.to be_truthy }
    end

    context 'when value includes accents' do
      let(:value) { 'tech@démarches.gouv.fr' }
      it { is_expected.to be_truthy }
    end

    context 'when value is the classic standard user@domain.ext' do
      let(:value) { 'username@mailserver.domain' }
      it { is_expected.to be_truthy }
    end
  end
end
