describe Champs::EmailChamp do
  describe 'validation' do
    let(:champ) { described_class.new(value:, dossier: build(:dossier)) }
    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_email)) }
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

    context 'when value comes from pentesters with \u0022' do
      let(:value) { "testing@example.com\u0022onmouseover=uzcc(96363)\u0022" }
      # what we allowed but it was a mistake
      it { is_expected.to be_falsey }
    end

    context 'when value comes from pentesters with script' do
      let(:value) { "testing@example.com<script>alert('ok')</script>" }
      # what we allowed but it was a mistake
      it { is_expected.to be_falsey }
    end

    context 'when value comes from pentesters with ?' do
      let(:value) { "testing@example.com?test" }
      # what we allowed but it was a mistake
      it { is_expected.to be_falsey }
    end

    context 'when value include an alias' do
      let(:value) { 'username+alias@mailserver.fr' }
      it { is_expected.to be_truthy }
    end

    context 'when value include an dash in domain' do
      let(:value) { 'username+alias@demarches-simplifiees.fr' }
      it { is_expected.to be_truthy }
    end

    context 'when value include an dash in domain' do
      let(:value) { 'username+alias@demarches-simplifiees-v2.fr' }
      it { is_expected.to be_truthy }
    end

    context 'when value includes accents' do
      let(:value) { 'tech@démarches.gouv.fr' }
      it { is_expected.to be_truthy }
    end

    context 'when value includes accents' do
      let(:value) { 'prenom.nom@etu.univ-rouen.fr' }
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
