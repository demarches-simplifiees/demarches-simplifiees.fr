# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241018fixFollowsWithNilPiecesJointesSeenAtTask do
    describe "#process" do
      subject { described_class.process(follow) }

      let(:follow) { create(:follow) }

      before { follow.update_columns(pieces_jointes_seen_at: nil) }

      it "updates the pieces_jointes_seen_at attribute" do
        expect { subject }.to change { follow.pieces_jointes_seen_at }.from(nil).to be_within(1.second).of(Time.zone.now)
      end
    end
  end
end
