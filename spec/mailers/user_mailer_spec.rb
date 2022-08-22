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

  describe '.ask_for_merge' do
    let(:requested_email) { 'new@exemple.fr' }

    subject { described_class.ask_for_merge(user, requested_email) }

    it { expect(subject.to).to eq([requested_email]) }
    it { expect(subject.body).to include(requested_email) }
  end

  describe '.france_connect_merge_confirmation' do
    let(:email) { 'new.exemple.fr' }
    let(:code) { '123456' }

    subject { described_class.france_connect_merge_confirmation(email, code, 15.minutes.from_now) }

    it { expect(subject.to).to eq([email]) }
    it { expect(subject.body).to include(france_connect_particulier_mail_merge_with_existing_account_url(merge_token: code)) }
  end

  describe '.send_archive' do
    let(:procedure) { create(:procedure) }
    let(:archive) { create(:archive) }
    subject { described_class.send_archive(role, procedure, archive) }

    context 'instructeur' do
      let(:role) { create(:instructeur) }
      it { expect(subject.to).to eq([role.user.email]) }
      it { expect(subject.body).to have_link('Consulter mes archives', href: instructeur_archives_url(procedure)) }
      it { expect(subject.body).to have_link("#{procedure.id} − #{procedure.libelle}", href: instructeur_procedure_url(procedure)) }
    end

    context 'instructeur' do
      let(:role) { create(:administrateur) }
      it { expect(subject.to).to eq([role.user.email]) }
      it { expect(subject.body).to have_link('Consulter mes archives', href: admin_procedure_archives_url(procedure)) }
      it { expect(subject.body).to have_link("#{procedure.id} − #{procedure.libelle}", href: admin_procedure_url(procedure)) }
    end
  end
end
