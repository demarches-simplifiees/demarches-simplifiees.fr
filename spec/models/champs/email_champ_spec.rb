describe Champs::EmailChamp do
  describe 'validation' do
    let(:champ) { build(:champ_email, value: value) }

    subject { champ.validate(:champs_public_value) }

    context 'when nil' do
      let(:value) { nil }

      it { is_expected.to be_truthy }
    end

    context 'when value is username' do
      let(:value) { 'username' }
      # what we allowed but it was a mistake
      it { is_expected.to be_falsey }
    end

    context 'when value does not contain extension' do
      let(:value) { 'username@mailserver' }
      # what we allowed but it was a mistake
      it { is_expected.to be_falsey }
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

    context 'when value contains white spaces plus a standard email' do
      let(:value) { "\r\n\t username@mailserver.domain\r\n\t " }
      it { is_expected.to be_truthy }
      it 'normalize value' do
        expect { subject }.to change { champ.value }.from(value).to('username@mailserver.domain')
      end
    end
  end
end
