# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe FixDureeConservationGreaterThanMaxDureeConservationTask do
    describe "#process" do
      subject(:process) do
        described_class.process(procedure)
      end

      let(:procedure) { create(:procedure, :published) }

      before { procedure.update_column(:duree_conservation_dossiers_dans_ds, 60) }

      it 'fixes invalid procedure' do
        expect(procedure.duree_conservation_dossiers_dans_ds).to eq 60
        expect(procedure).to be_invalid
        subject
        expect(procedure.duree_conservation_dossiers_dans_ds).to eq 36
        expect(procedure).to be_valid
      end
    end
  end
end
