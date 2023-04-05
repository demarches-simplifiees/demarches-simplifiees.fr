# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attachment::PendingPollComponent, type: :component do
  let(:champ) { create(:champ_titre_identite) }
  let(:attachment) { champ.piece_justificative_file.attachments.first }
  let(:component) {
    described_class.new(poll_url: "poll-here", attachment:)
  }

  subject {
    render_inline(component).to_html
  }

  context "when watermark is pending" do
    it "renders turbo poll attributes" do
      expect(subject).to have_selector("[data-controller='turbo-poll'][data-turbo-poll-url-value='poll-here']")
    end

    it "renders" do
      expect(component).to be_render
    end

    it "does not render manual reload" do
      expect(component).not_to have_content("Recharger")
    end

    context "when watermark is pending for a long time" do
      before do
        attachment.created_at = 5.minutes.ago
      end

      it "renders manual reload" do
        expect(subject).to have_content("Recharger")
      end
    end
  end

  context "when waterkmark is done" do
    before do
      attachment.blob[:metadata] = { watermark: true }
    end

    it "does not render" do
      expect(component).not_to be_render
    end

    context "when antivirus is in progress" do
      before do
        attachment.blob[:metadata] = { virus_scan_result: ActiveStorage::VirusScanner::PENDING }
      end

      it "renders" do
        expect(component).to be_render
      end
    end
  end
end
