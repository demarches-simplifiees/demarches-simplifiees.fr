# frozen_string_literal: true

RSpec.describe ProcedureSVASVRProcessDossierJob, type: :job do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  before do
    travel_to Date.new(2023, 8, 15, 12)
  end

  let(:procedure) { create(:procedure, :published, :sva, :for_individual) }
  let!(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure:, depose_at: 2.months.ago - 1.day, sva_svr_decision_on: Date.current) }

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
      let!(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure:, depose_at: 1.day.ago, sva_svr_decision_on: 2.months.from_now.to_date) }

      it 'should not accept dossier' do
        expect { subject }.not_to change { dossier.reload.updated_at }
        expect(subject).to be_en_instruction
      end
    end

    context 'when dossier has pending correction / is en_construction' do
      before do
        travel_to 2.days.ago do # create correction in past so it will be 3 days of delay
          dossier.flag_as_pending_correction!(build(:commentaire, dossier: dossier))
        end
      end

      it 'should not accept dossier' do
        subject
        expect(dossier).to be_en_construction
      end

      it 'should update sva_svr_decision_on with corrections delay' do
        expect { subject }.to change { dossier.reload.sva_svr_decision_on }.from(Date.current).to(Date.current + 3.days)
      end
    end
  end

  context 'when procedure is SVR' do
    let(:procedure) { create(:procedure, :published, :svr, :for_individual) }

    it 'should refuse dossier' do
      expect(subject.sva_svr_decision_on).to eq(Date.current)
      expect(subject).to be_refuse
      expect(subject.processed_at).to within(1.second).of(Time.current)
    end

    context 'when decision is scheduled in the future' do
      let!(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure:, depose_at: 1.day.ago, sva_svr_decision_on: 2.months.from_now.to_date) }

      it 'should not refuses dossier' do
        expect { subject }.not_to change { dossier.reload.updated_at }
        expect(subject).to be_en_instruction
      end
    end

    context 'when dossier has pending correction / is en_construction' do
      before do
        travel_to 2.days.ago do # create correction in past so it will be 3 days of delay
          dossier.flag_as_pending_correction!(build(:commentaire, dossier: dossier))
        end
      end

      it 'should not refuses dossier' do
        subject
        expect(dossier).to be_en_construction
      end

      it 'should update sva_svr_decision_on with corrections delay' do
        expect { subject }.to change { dossier.reload.sva_svr_decision_on }.from(Date.current).to(Date.current + 3.days)
      end
    end
  end

  context 'when dossier was submitted before sva was enabled' do
    let!(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure:, depose_at: 2.months.ago) }

    it 'should be noop' do
      expect(subject.sva_svr_decision_on).to be_nil
      expect(subject).to be_en_instruction
      expect(subject.processed_at).to be_nil
    end
  end
end
