RSpec.describe GestionnaireMailer, type: :mailer do
  describe '#send_dossier' do
    let(:sender) { create(:gestionnaire) }
    let(:recipient) { create(:gestionnaire) }
    let(:dossier) { create(:dossier) }

    subject { described_class.send_dossier(sender, dossier, recipient) }

    it { expect(subject.body).to include('Bonjour') }
  end

  describe '#last_week_overview' do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:procedure) { create(:procedure, :published, gestionnaires: [gestionnaire]) }
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

    before { allow(gestionnaire).to receive(:last_week_overview).and_return(last_week_overview) }

    subject { described_class.last_week_overview(gestionnaire) }

    it { expect(subject.body).to include('Votre activité hebdomadaire') }

    context 'when the gestionnaire has no active procedures' do
      let(:procedure) { nil }
      let(:last_week_overview) { nil }

      it 'doesn’t send the email' do
        expect(subject.message).to be_kind_of(ActionMailer::Base::NullMail)
        expect(subject.body).to be_blank
      end
    end
  end
end
