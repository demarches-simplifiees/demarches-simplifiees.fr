# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe DestroyProcedureWithoutAdministrateurAndWithoutDossierTask do
    describe "#process" do
      subject(:process) { described_class.process(procedure) }
      let(:procedure) { create(:procedure) }

      before do
        administrateur = procedure.administrateurs.first
        AdministrateursProcedure.where(administrateur_id: administrateur.id).delete_all
        administrateur.destroy
      end

      it "destroys procedure" do
        subject
        expect(Procedure.count).to eq 0
      end
    end
  end
end
