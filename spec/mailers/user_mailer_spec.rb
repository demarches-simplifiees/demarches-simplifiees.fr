RSpec.describe UserMailer, type: :mailer do
  let(:user) { build(:user) }

  describe '.new_account_warning' do
    subject { described_class.new_account_warning(user) }

    it { expect(subject.to).to eq([user.email]) }
    it { expect(subject.body).to include(user.email) }
    it { expect(subject.body).to have_link('J’ai oublié mon mot de passe') }

    context 'when a procedure is provided' do
      let(:procedure) { build(:procedure) }

      subject { described_class.new_account_warning(user, procedure) }

      it { expect(subject.body).to have_link("Commencer la démarche « #{procedure.libelle} »", href: commencer_sign_in_url(path: procedure.path)) }
    end
  end

  describe '.account_already_taken' do
    let(:requested_email) { 'new@exemple.fr' }

    subject { described_class.account_already_taken(user, requested_email) }

    it { expect(subject.to).to eq([requested_email]) }
    it { expect(subject.body).to include(requested_email) }
  end
end
