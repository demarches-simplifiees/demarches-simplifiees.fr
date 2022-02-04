RSpec.describe Cron::FillProcessedAtJob, type: :job do
  describe 'perform' do
    let(:mailer_double) { double('mailer', deliver_now: true) }
    let(:procedure) { create(:procedure) }

    before do
      allow(AdministrationMailer).to receive(:processed_at_filling_report).and_return(mailer_double)
      invalid_dossiers.each do |d|
        if d.processed_at
          d.processed_at = nil
          d.save
        end
      end
      Cron::FillProcessedAtJob.new.perform_now
    end

    context 'with dossiers without processed_at' do
      let(:dossier_correct) { create(:dossier, :accepte) }
      let(:dossier_incorrect) { create(:dossier, state: Dossier.states.fetch(:accepte)) }

      let(:valid_dossiers) { [create(:dossier, :en_construction), create(:dossier, :en_instruction), create(:dossier, :brouillon)] }
      let(:invalid_dossiers) { [create(:dossier, :accepte), create(:dossier, :refuse), create(:dossier, :sans_suite)] }

      it 'expect processed_at is nil' do
        invalid_dossiers.each do |d|
          expect(d.reload.processed_at).to be_truthy
        end
        valid_dossiers.each do |d|
          expect(d.reload.processed_at).to be_nil
        end
        expect(dossier_incorrect.reload.processed_at).to be_nil
      end
    end
  end
end
