RSpec.describe InstructeurMailer, type: :mailer do
  describe '#send_dossier' do
    let(:sender) { create(:instructeur) }
    let(:recipient) { create(:instructeur) }
    let(:dossier) { create(:dossier) }

    subject { described_class.send_dossier(sender, dossier, recipient) }

    it { expect(subject.body).to include('Bonjour') }
  end

  describe '#last_week_overview' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
    let(:dossier) { create(:dossier) }
    let(:last_week_overview) do
      procedure_overview = double('po',
        procedure: procedure,
        created_dossiers_count: 0,
        dossiers_en_construction_count: 1,
        old_dossiers_en_construction: [dossier],
        dossiers_en_construction_description: 'desc',
        dossiers_en_instruction_count: 1,
        old_dossiers_en_instruction: [dossier],
        dossiers_en_instruction_description: 'desc')

      {
        start_date: Time.zone.now,
        procedure_overviews: [procedure_overview]
      }
    end

    before { allow(instructeur).to receive(:last_week_overview).and_return(last_week_overview) }

    subject { described_class.last_week_overview(instructeur) }

    it { expect(subject.body).to include('Votre activité hebdomadaire') }

    context 'when the instructeur has no active procedures' do
      let(:procedure) { nil }
      let(:last_week_overview) { nil }

      it 'doesn’t send the email' do
        expect(subject.message).to be_kind_of(ActionMailer::Base::NullMail)
        expect(subject.body).to be_blank
      end
    end
  end

  describe '#notify_procedure_export_available' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:format) { 'xlsx' }

    context 'when the mail is sent' do
      subject { described_class.notify_procedure_export_available(instructeur, procedure, format) }
      it 'contains a download link' do
        expect(subject.body).to include download_export_instructeur_procedure_url(procedure, :export_format => format)
      end
    end
  end
end
