# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250804destroyDossierDeposeNotificationOfGroupeInstructeurTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      context 'dossier_depose notification is linked to a groupe_instructeur' do
        let!(:notification) { create(:dossier_notification, :for_groupe_instructeur, groupe_instructeur: create(:groupe_instructeur), dossier: create(:dossier)) }

        it do
          expect(collection.flat_map(&:to_a)).to include(notification)
        end
      end

      context 'dossier_depose notification is linked to an instructeur' do
        let!(:notification) { create(:dossier_notification, :for_instructeur, instructeur: create(:instructeur), dossier: create(:dossier)) }

        it do
          expect(collection.flat_map(&:to_a)).not_to include(notification)
        end
      end
    end
  end
end
