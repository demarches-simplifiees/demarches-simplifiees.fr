# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250721destroyOrphanFollowsTask do
    describe "#collection" do
      subject(:collection) { described_class.collection }

      let(:dossier) { create(:dossier) }
      let(:instructeur) { create(:instructeur) }
      let!(:valid_follow) { create(:follow, dossier:, instructeur:) }

      # Following the insertion of constraints into the database by #11970,
      # these must be bypassed in order to create orphan follows.
      before do
        Follow.connection.execute("ALTER TABLE follows DISABLE TRIGGER ALL")

        Follow.connection.execute <<~SQL.squish
          INSERT INTO follows (instructeur_id, dossier_id, annotations_privees_seen_at, avis_seen_at, demande_seen_at, messagerie_seen_at, created_at, updated_at)
          VALUES (9999, #{valid_follow.dossier_id}, NOW(), NOW(), NOW(), NOW(), NOW(), NOW())
        SQL

        Follow.connection.execute <<~SQL.squish
          INSERT INTO follows (instructeur_id, dossier_id, annotations_privees_seen_at, avis_seen_at, demande_seen_at, messagerie_seen_at, created_at, updated_at)
          VALUES (#{valid_follow.instructeur_id}, 9999, NOW(), NOW(), NOW(), NOW(), NOW(), NOW())
        SQL

        Follow.connection.execute("ALTER TABLE follows ENABLE TRIGGER ALL")
      end

      it "includes follows with missing instructeur or dossier" do
        result = collection.flat_map(&:to_a)

        expect(result.count).to eq(2)
        expect(result).not_to include(valid_follow)
        expect(result.map(&:instructeur_id)).to include(9999)
        expect(result.map(&:dossier_id)).to include(9999)
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
