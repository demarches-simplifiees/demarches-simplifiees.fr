# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250414backfillUserIdInProConnectInformationTask do
    describe '#collection' do
      subject(:collection) { described_class.new.collection }

      let(:instructeur) { create(:instructeur) }
      let!(:pro_connect_information_without_user) { create(:pro_connect_information, user_id: nil, instructeur:) }
      let!(:pro_connect_information_with_user) { create(:pro_connect_information, user: instructeur.user, instructeur:) }

      it 'returns only pro_connect_informations without user_id' do
        expect(collection).to contain_exactly(pro_connect_information_without_user)
      end
    end

    describe '#process' do
      subject(:process) { described_class.new.process(pro_connect_information) }

      let(:instructeur) { create(:instructeur) }
      let(:pro_connect_information) { create(:pro_connect_information, user_id: nil, instructeur:) }

      it 'updates the user_id with the instructeur user_id' do
        expect { process }.to change { pro_connect_information.reload.user_id }.from(nil).to(instructeur.user_id)
      end
    end

    describe '#count' do
      subject(:count) { described_class.new.count }

      let(:instructeur) { create(:instructeur) }

      before do
        create(:pro_connect_information, user_id: nil, instructeur:)
        create(:pro_connect_information, user: instructeur.user, instructeur:)
      end

      it 'returns the count of pro_connect_informations without user_id' do
        expect(count).to eq(1)
      end
    end
  end
end
