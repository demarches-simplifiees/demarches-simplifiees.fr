# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241202removeUnusedForksTask do
    describe "#process" do
      subject(:collection) { described_class.collection }
      let(:procedure) { create(:procedure) }
      let(:dossier1) { create(:dossier, :en_construction, procedure:) }
      let(:dossier2) { create(:dossier, :en_instruction, procedure:) }
      let(:dossier3) { create(:dossier, :accepte, procedure:) }

      before do
        dossier1.owner_editing_fork
        dossier2.owner_editing_fork
        dossier3.owner_editing_fork
      end

      it { is_expected.to match_array([dossier2.owner_editing_fork, dossier3.owner_editing_fork]) }
    end
  end
end
