RSpec.describe NotificationMailer, type: :mailer do
  let(:administrateur) { create(:administrateur) }
  let(:user) { create(:user) }
  let(:procedure) { create(:simple_procedure, :with_service) }

  describe 'send_notification_for_tiers' do
    let(:dossier_for_tiers) { create(:dossier, :en_construction, :for_tiers_with_notification, procedure: create(:simple_procedure)) }

    subject { described_class.send_notification_for_tiers(dossier_for_tiers) }

    it { expect(subject.subject).to include("Votre dossier rempli par le mandataire #{dossier_for_tiers.mandataire_first_name} #{dossier_for_tiers.mandataire_last_name} a été mis à jour") }
    it { expect(subject.to).to eq([dossier_for_tiers.individual.email]) }
    it { expect(subject.body).to include("Pour en savoir plus, veuillez vous rapprocher de\r\n<a href=\"mailto:#{dossier_for_tiers.user.email}\">#{dossier_for_tiers.user.email}</a>.") }
  end

  describe 'send_en_construction_notification' do
    let(:dossier) { create(:dossier, :en_construction, :with_individual, user: user, procedure:) }

    subject(:mail) { described_class.send_en_construction_notification(dossier) }

    let(:body) { (mail.html_part || mail).body }

    context "without custom template" do
      it 'renders default template' do
        expect(mail.subject).to eq("Votre dossier nº #{dossier.id} a bien été déposé (#{procedure.libelle})")
        expect(body).to include("Votre dossier nº #{dossier.id}")
        expect(body).to include(procedure.service.nom)
        expect(mail.attachments.first.filename).to eq("attestation-de-depot.pdf")
      end
    end

    context "with a custom template" do
      let(:email_template) { create(:initiated_mail, subject: 'Email subject', body: 'Your dossier was received. Thanks.', procedure:) }

      before do
        dossier.procedure.initiated_mail = email_template
      end

      it 'renders the template' do
        expect(mail.subject).to eq('Email subject')
        expect(body).to include('Your dossier was received')
        expect(mail.attachments.first.filename).to eq("attestation-de-depot.pdf")
      end
    end
  end

  describe 'send_en_instruction_notification' do
    let(:dossier) { create(:dossier, :en_instruction, :with_individual, :with_service, user: user, procedure:) }
    let(:email_template) { create(:received_mail, subject: 'Email subject', body: 'Your dossier was processed. Thanks.', procedure:) }

    before do
      dossier.procedure.received_mail = email_template
    end

    subject(:mail) { described_class.send_en_instruction_notification(dossier) }

    it 'renders the template' do
      expect(mail.subject).to eq('Email subject')
      expect(mail.body).to include('Your dossier was processed')
      expect(mail.body).to have_link('messagerie')
    end

    it 'renders the actions' do
      expect(mail.body).to have_link('Consulter mon dossier', href: dossier_url(dossier))
      expect(mail.body).to have_link('J’ai une question', href: messagerie_dossier_url(dossier))
    end

    context 'when the template body contains tags' do
      let(:email_template) { create(:received_mail, subject: 'Email subject', body: 'Hello --nom--, your dossier --lien dossier-- was processed.', procedure:) }

      it 'replaces value tags with the proper value' do
        expect(mail.body).to have_content(dossier.individual.nom)
      end

      it 'replaces link tags with a clickable link' do
        expect(mail.body).to have_link(dossier_url(dossier))
      end
    end

    context 'when the template body contains HTML' do
      let(:email_template) { create(:received_mail, body: 'Your <b>dossier</b> was processed. <iframe src="#">Foo</iframe>', procedure:) }

      it 'allows basic formatting tags' do
        expect(mail.body).to include('<b>dossier</b>')
      end

      it 'sanitizes sensitive content' do
        expect(mail.body).not_to include('iframe')
      end
    end

    it 'sends the mail from a no-reply address' do
      expect(subject.from.first).to eq(Mail::Address.new(NO_REPLY_EMAIL).address)
    end
  end

  describe 'subject length' do
    let(:procedure) { create(:simple_procedure, libelle: "My super long title " + ("xo " * 100)) }
    let(:dossier) { create(:dossier, :accepte, :with_individual, :with_service, user: user, procedure:) }
    let(:email_template) { create(:closed_mail, subject:, body: 'Your dossier was accepted. Thanks.', procedure:) }

    before do
      dossier.procedure.closed_mail = email_template
    end

    subject(:mail) { described_class.send_accepte_notification(dossier) }

    context "subject is too long" do
      let(:subject) { 'Un long libellé --libellé démarche--' }
      it { expect(mail.subject.length).to be <= 100 }
    end

    context "subject should fallback to default" do
      let(:subject) { "" }
      it { expect(mail.subject).to match(/^Votre dossier .+ a été accepté \(My super long title/) }
      it { expect(mail.subject.length).to be <= 100 }
    end
  end

  describe 'subject with apostrophe' do
    let(:procedure) { create(:simple_procedure, libelle: "Mon titre avec l'apostrophe") }
    let(:dossier) { create(:dossier, :en_instruction, :with_individual, :with_service, user: user, procedure:) }
    let(:email_template) { create(:received_mail, subject:, body: 'Your dossier was accepted. Thanks.', procedure:) }

    before do
      dossier.procedure.received_mail = email_template
    end

    subject(:mail) { described_class.send_en_instruction_notification(dossier) }

    context "subject has a special character" do
      let(:subject) { '--libellé démarche--' }
      it { expect(mail.subject).to eq("Mon titre avec l'apostrophe") }
    end
  end
end
