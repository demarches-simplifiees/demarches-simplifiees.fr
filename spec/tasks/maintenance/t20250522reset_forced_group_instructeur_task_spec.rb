# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250522resetForcedGroupInstructeurTask do
    describe "#process" do
      let(:admin) { administrateurs(:default_admin) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :departements, libelle: 'Votre département' }], administrateurs: [admin]) }
      let(:dossier1) { create(:dossier, :en_construction, :with_populated_champs, procedure: procedure, forced_groupe_instructeur: true) }
      let!(:dossier2) { create(:dossier, :en_construction, :with_populated_champs, procedure: procedure) }

      it 'runs' do
        described_class.process(dossier1)
        dossier1.reload
        expect(dossier1.forced_groupe_instructeur).to be_falsey

        described_class.process(dossier2)
        dossier2.reload
        expect(dossier2.forced_groupe_instructeur).to be_falsey
      end
    end
  end
end
