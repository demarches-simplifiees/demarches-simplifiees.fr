# frozen_string_literal: true

RSpec.describe Dossiers::BatchAlertComponent, type: :component do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }

  subject { render_inline(component).to_html }
  let(:component) do
    described_class.new(
      batch: batch_operation,
      procedure:
    )
  end
  before do
    allow(component).to receive(:procedure_path).and_return(Rails.application.routes.url_helpers.instructeur_procedure_path(procedure, statut: 'a-suivre'))
  end

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
      it { is_expected.to have_text("Cette opération a été lancée par #{instructeur.email}, il y a moins d'une minute") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
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
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été archivés") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
      end
    end
  end

  describe 'desarchiver' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :accepte, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :accepte, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :desarchiver, dossiers: [dossier, dossier_2], instructeur: instructeur) }
    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été désarchivés") }
      it { is_expected.to have_text("Cette opération a été lancée par #{instructeur.email}, il y a moins d'une minute") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été désarchivés") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été désarchivés") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
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
      it { is_expected.to have_text("L’action de masse est terminée") }
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
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été passés en instruction") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
      end
    end
  end

  describe 'repousser_expiration' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :accepte, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :accepte, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :repousser_expiration, dossiers: [dossier, dossier_2], instructeur: instructeur) }
    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers seront conservé 1 mois supplémentaire") }
      it { is_expected.to have_text("Cette opération a été lancée par #{instructeur.email}, il y a moins d'une minute") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers seront conservé 1 mois supplémentaire") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers seront conservé 1 mois supplémentaire") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
      end
    end
  end

  describe 'accepter' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :en_instruction, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :accepter, dossiers: [dossier, dossier_2], instructeur: instructeur) }

    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été acceptés") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été acceptés") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été acceptés") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
      end
    end
  end

  describe 'refuser' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :en_instruction, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :refuser, dossiers: [dossier, dossier_2], instructeur: instructeur) }

    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été refusés") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été refusés") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end
  end

  describe 'classer_sans_suite' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :en_instruction, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :classer_sans_suite, dossiers: [dossier, dossier_2], instructeur: instructeur) }

    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été classés sans suite") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été classés sans suite") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end
  end

  describe 'follow' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :en_instruction, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :follow, dossiers: [dossier, dossier_2], instructeur: instructeur) }

    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été suivis") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été suivis") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été suivis") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
      end
    end
  end

  describe 'unfollow' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :en_construction, :followed, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :en_instruction, :followed, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :unfollow, dossiers: [dossier, dossier_2], instructeur: instructeur) }

    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ne sont plus suivis") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ne sont plus suivis") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ne sont plus suivis") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
      end
    end
  end

  describe 'restaurer' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :accepte, procedure: procedure, hidden_by_administration_at: Time.zone.now) }
    let!(:dossier_2) { create(:dossier, :accepte, procedure: procedure, hidden_by_administration_at: Time.zone.now) }
    let!(:batch_operation) { create(:batch_operation, operation: :restaurer, dossiers: [dossier, dossier_2], instructeur: instructeur) }

    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été restaurés") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été restaurés") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été restaurés") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
      end
    end
  end

  describe 'repasser en construction' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :en_instruction, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :repasser_en_construction, dossiers: [dossier, dossier_2], instructeur: instructeur) }

    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été repassés en construction") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été repassés en construction") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été repassés en construction") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
      end
    end
  end

  describe 'supprimer' do
    let(:component) do
      described_class.new(
        batch: batch_operation,
        procedure: procedure
      )
    end
    let!(:dossier) { create(:dossier, :accepte, procedure: procedure) }
    let!(:dossier_2) { create(:dossier, :accepte, procedure: procedure) }
    let!(:batch_operation) { create(:batch_operation, operation: :supprimer, dossiers: [dossier, dossier_2], instructeur: instructeur) }

    context 'in_progress' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--info') }
      it { is_expected.to have_text("Une action de masse est en cours") }
      it { is_expected.to have_text("1/2 dossiers ont été supprimés") }
    end

    context 'finished and success' do
      before {
         batch_operation.track_processed_dossier(true, dossier)
         batch_operation.track_processed_dossier(true, dossier_2)
         batch_operation.reload
       }

      it { is_expected.to have_selector('.fr-alert--success') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("2 dossiers ont été supprimés") }
      it { expect(batch_operation.seen_at).to eq(nil) }
    end

    context 'finished and fail' do
      before {
        batch_operation.track_processed_dossier(false, dossier)
        batch_operation.track_processed_dossier(true, dossier_2)
        batch_operation.reload
      }

      it { is_expected.to have_selector('.fr-alert--warning') }
      it { is_expected.to have_text("L’action de masse est terminée") }
      it { is_expected.to have_text("1/2 dossiers ont été supprimés") }
      it { expect(batch_operation.seen_at).to eq(nil) }

      it 'on next render "seen_at" is set to avoid rendering alert' do
        render_inline(described_class.new(batch: batch_operation, procedure:)).to_html
        expect(batch_operation.seen_at).not_to eq(nil)
      end
    end
  end
end
