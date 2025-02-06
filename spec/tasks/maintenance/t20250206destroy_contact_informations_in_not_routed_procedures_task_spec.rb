# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250206destroyContactInformationsInNotRoutedProceduresTask do
    describe "#process" do
      subject(:process) { described_class.process(element) }
      let!(:groupe_instructeur) { create(:groupe_instructeur) }
      let!(:contact_information) { create(:contact_information, groupe_instructeur:) }

      it do
        expect(groupe_instructeur.contact_information).not_to be_nil
        described_class.process(groupe_instructeur)
        expect(groupe_instructeur.reload.contact_information).to be_nil
      end
    end
  end
end
