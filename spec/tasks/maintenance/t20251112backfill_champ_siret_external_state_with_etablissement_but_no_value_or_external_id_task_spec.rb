# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251112backfillChampSiretExternalStateWithEtablissementButNoValueOrExternalIdTask do
    describe "#process" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :siret }]) }
      let(:etablissement) { create(:etablissement, siret: "44011762001530") }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:, etablissement:) }
      let(:champ) { dossier.project_champs_public.first }

      subject(:process) { described_class.process(Champs::SiretChamp.all) }

      before do
        champ.update_columns(etablissement_id: etablissement.id, value: nil, external_id: nil, external_state: :fetched)
      end

      context 'when champ has an etablissement' do
        it 'backfills the value and external_id with etablissement siret' do
          expect { subject }.to change { champ.reload.value }.from(nil).to(etablissement.siret)
          expect(champ.external_id).to eq(etablissement.siret)
        end
      end
    end
  end
end
