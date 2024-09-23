# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe ResolvePendingCorrectionForDossierWithInvalidCommuneExternalIdTask do
    describe "#process" do
      subject(:process) { described_class.process }
      let!(:instructeur) { create(:instructeur, email: ENV.fetch('DEFAULT_INSTRUCTEUR_EMAIL') { CONTACT_EMAIL }) }
      let(:commentaire) { create(:commentaire, instructeur:) }
      let(:dossier_correction) { create(:dossier_correction, commentaire:, dossier:, resolved_at: nil) }

      before { dossier_correction }

      context 'when dossier did transitioned to en_construction from en_instruction' do
        let(:dossier) { create(:dossier, :en_instruction) }
        before { dossier.repasser_en_construction!(instructeur:) }
        it 'goes back to en_instruction (my mistake, sorry dear colleague, users etc...)' do
          expect { subject }.to change { dossier.reload.state }.from('en_construction').to('en_instruction')
        end
      end

      context 'when dossier didnt transitioned' do
        let(:dossier) { create(:dossier, :en_construction) }
        before { create(:traitement, dossier:) }
        it 'noop' do
          expect { subject }.not_to change { dossier.reload.state }
        end
      end
    end
  end
end
