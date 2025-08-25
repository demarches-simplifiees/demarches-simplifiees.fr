# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250813removeDuplicateExpertsTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let(:user_with_duplicates) { create(:user) }
      let!(:oldest_expert) { create(:expert, user: user_with_duplicates, created_at: 3.days.ago) }
      let!(:newer_expert) { create(:expert, user: user_with_duplicates, created_at: 1.day.ago) }
      let(:user_without_duplicates) { create(:user) }
      let!(:single_expert) { create(:expert, user: user_without_duplicates) }

      it 'returns only the experts that are duplicates' do
        expect(collection).to include(newer_expert)
        expect(collection).not_to include(oldest_expert, single_expert)
      end
    end
  end
end
