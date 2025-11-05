# frozen_string_literal: true

require "rails_helper"

module Maintenance
  describe BackfillDepartementServicesTask do
    describe "#process" do
      subject(:process) { described_class.process(service) }
      context 'with service with code_insee_localite' do
        let(:service) {
          create(:service,
                 etablissement_infos: {
                   adresse: "70 rue du Louvre\n75002\nPARIS\nFRANCE",
                   code_insee_localite: "75002",
                 })
        }

        it "updates departement" do
          subject
          expect(service.reload.departement).to eq "75"
        end
      end

      context 'with service with code_insee_localite' do
        let(:service) {
          create(:service,
                 etablissement_infos: {
                   adresse: "70 rue du Louvre\n75002\nPARIS\nFRANCE",
                 })
        }
        it 'does nothing if no code_insee_localite' do
          subject
          expect(service.reload.departement).to eq nil
        end
      end
    end
  end
end
