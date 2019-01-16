require 'spec_helper'

load Rails.root.join('lib', 'tasks', '2019_01_16_fix_automatic_dossier_logs.rake')

describe '2019_01_16_fix_automatic_dossier_logs' do
  let!(:rake_task) { Rake::Task['2019_01_16_fix_automatic_dossier_logs:run'] }
  let!(:administrateur) { create(:administrateur) }
  let!(:another_gestionnaire) { create(:gestionnaire) }
  let!(:procedure) { create(:procedure, administrateur: administrateur) }
  let!(:dossier) { create(:dossier, procedure: procedure) }
  let!(:fix_automatic_dossier_logs) { FixAutomaticDossierLogs_2019_01_16.new }

  before do
    allow(fix_automatic_dossier_logs).to receive(:find_handlers)
      .and_return([double(job_data: { 'arguments' => [procedure.id, final_state] })])
  end

  subject do
    fix_automatic_dossier_logs.run
    dossier.reload
  end

  context 'when the dossiers are automatically moved to en_instruction' do
    let(:final_state) { 'en_instruction' }

    context 'and a dossier has been accidentally affected to an administrateur' do
      before do
        dossier.passer_en_instruction!(administrateur.gestionnaire)

        control = DossierOperationLog.create(
          gestionnaire: another_gestionnaire,
          operation: 'refuser',
          automatic_operation: false
        )

        dossier.dossier_operation_logs << control
        subject
      end

      it { expect(dossier.follows.count).to eq(0) }

      it do
        expect(dossier_logs).to match_array([
          [nil, 'passer_en_instruction', true],
          [another_gestionnaire.id, "refuser", false]
        ])
      end
    end

    context ', followed anyway by another person and accidentally ...' do
      before do
        another_gestionnaire.follow(dossier)
        dossier.passer_en_instruction!(administrateur.gestionnaire)

        subject
      end

      it { expect(dossier.follows.count).to eq(2) }
      it { expect(dossier_logs).to match([[nil, 'passer_en_instruction', true]]) }
    end
  end

  context 'when the dossiers are automatically moved to accepte' do
    let(:final_state) { 'accepte' }

    context 'and a dossier has been accidentally affected to an administrateur' do
      before do
        dossier.accepter!(administrateur.gestionnaire, '')

        subject
      end

      it { expect(dossier_logs).to match([[nil, 'accepter', true]]) }
    end
  end

  private

  def dossier_logs
    dossier.dossier_operation_logs.pluck(:gestionnaire_id, :operation, :automatic_operation)
  end
end
