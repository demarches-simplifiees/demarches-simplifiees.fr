# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe RemovePieceJustificativeFileNotVisibleTask do
    describe "#process" do
      subject(:process) { described_class.process(dossier) }

      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
      let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure:) }

      before { expect(champ).to receive(:visible?).and_return(visible) }

      context 'when piece_justificative' do
        let(:champ) { dossier.champs_for_revision(scope: :public).find(&:piece_justificative?) }

        context 'when not visible' do
          let(:visible) { false }
          it { expect { subject }.to change { champ.reload.piece_justificative_file.attached? } }
        end

        context 'when visible' do
          let(:visible) { true }
          it { expect { subject }.not_to change { champ.reload.piece_justificative_file.attached? } }
        end
      end
    end
  end
end
