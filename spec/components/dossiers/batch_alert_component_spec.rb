RSpec.describe Dossiers::BatchAlertComponent, type: :component do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }

  subject { render_inline(component).to_html }

  describe 'archiver' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :accepte, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :accepte, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :archiver, dossiers: [dossier, dossier_2], instructeur: instructeur) }
    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été archivés") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L'action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été archivés") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L'action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été archivés") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'does not display alert on the next render' do
        render_inline(component).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
        expect(subject).not_to have_text("1 dossier n'a pas été archivé")
      end
    end
  end

  describe 'passer_en_instruction' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :en_construction, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :passer_en_instruction, dossiers: [dossier, dossier_2], instructeur: instructeur) }

    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été passés en instruction") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L'action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été passés en instruction") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L'action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été passés en instruction") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'does not display alert on the next render' do
        render_inline(component).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
        expect(subject).not_to have_text("1 dossier n'a pas passé en instruction")
      end
    end
  end
end
