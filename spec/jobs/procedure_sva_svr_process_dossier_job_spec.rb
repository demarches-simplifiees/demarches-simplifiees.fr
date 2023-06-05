RSpec.describe ProcedureSVASVRProcessDossierJob, type: :job do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:procedure) { create(:procedure, :published, :sva, :for_individual) }
  let!(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure:, depose_at: 2.months.ago, sva_svr_decision_on: Date.current) }

  subject do
    described_class.perform_now(dossier)
    dossier.reload
  end

  context 'when procedure is SVA' do
    it 'should accept dossier' do
      expect(subject.sva_svr_decision_on).to eq(Date.current)
      expect(subject).to be_accepte
      expect(subject.processed_at).to within(1.second).of(Time.current)
    end

    context 'when decision is scheduled in the future' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure:, depose_at: 1.day.ago, sva_svr_decision_on: Date.yesterday + 2.months) }

      it 'should not accept dossier' do
        expect { subject }.not_to change { dossier.reload.updated_at }
        expect(subject).to be_en_instruction
      end
    end

    context 'when dossier has pending correction / is en_construction' do
      before do
        travel_to 2.days.ago do # create correction in past so it will be 2 days of delay
          dossier.flag_as_pending_correction!(build(:commentaire, dossier: dossier))
        end
      end

      it 'should not accept dossier' do
        subject
        expect(dossier).to be_en_construction
      end

      it 'should update sva_svr_decision_on with corrections delay' do
        expect { subject }.to change { dossier.reload.sva_svr_decision_on }.from(Date.current).to(Date.current + 2.days)
      end
    end
  end
end
