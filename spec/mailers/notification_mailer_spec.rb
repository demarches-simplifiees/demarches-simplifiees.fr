RSpec.describe NotificationMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:procedure) { create(:simple_procedure) }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, :with_service, user: user, procedure: procedure) }

  describe '.send_dossier_received' do
    let(:email_template) { create(:received_mail, subject: 'Email subject', body: 'Your dossier was processed. Thanks.') }

    before do
      dossier.procedure.received_mail = email_template
    end

    subject(:mail) { described_class.send_dossier_received(dossier) }

    it 'creates a commentaire in the messagerie' do
      expect { subject.deliver_now }.to change { Commentaire.count }.by(1)

      commentaire = Commentaire.last
      expect(commentaire.body).to include(email_template.subject_for_dossier(dossier), email_template.body_for_dossier(dossier))
      expect(commentaire.dossier).to eq(dossier)
    end

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
      let(:email_template) { create(:received_mail, subject: 'Email subject', body: 'Hello --nom--, your dossier --lien dossier-- was processed.') }

      it 'replaces value tags with the proper value' do
        expect(mail.body).to have_content(dossier.individual.nom)
      end

      it 'replaces link tags with a clickable link' do
        expect(mail.body).to have_link(dossier_url(dossier))
      end
    end

    context 'when the template body contains HTML' do
      let(:email_template) { create(:received_mail, body: 'Your <b>dossier</b> was processed. <iframe src="#">Foo</iframe>') }

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
end
