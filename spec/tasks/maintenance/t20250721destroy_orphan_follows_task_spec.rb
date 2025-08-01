# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250721destroyOrphanFollowsTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let(:orphan_instructeur_follow) { create(:follow) }
      let(:orphan_dossier_follow) { create(:follow) }
      let(:valid_follow) { create(:follow) }

      before do
        orphan_instructeur_follow.update_column(:instructeur_id, 9999)
        orphan_dossier_follow.update_column(:dossier_id, 9999)
      end

      it "includes follows with missing instructeur or dossier" do
        expect(collection.flat_map(&:to_a)).to include(orphan_instructeur_follow, orphan_dossier_follow)
        expect(collection.flat_map(&:to_a)).not_to include(valid_follow)
      end
    end

    describe "#process" do
      subject(:process) { described_class.process(Follow.where(id: orphan_follows)) }

      let!(:orphan_follows) { create_list(:follow, 3) }

      it 'destroy follow' do
        expect { process }.to change { Follow.count }.by(-3)
      end
    end
  end
end
