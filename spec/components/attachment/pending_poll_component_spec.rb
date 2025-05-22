# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attachment::PendingPollComponent, type: :component do
  let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
  let(:types_de_champ_public) { [{ type: :titre_identite }] }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ) { dossier.champs.first }

  let(:attachment) { champ.piece_justificative_file.attachments.first }

  let(:component) { described_class.new(poll_url: "poll-here", attachment:) }

  subject { render_inline(component).to_html }

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
      attachment.blob.touch(:watermarked_at)
    end

    it "does not render" do
      expect(component).not_to be_render
    end
  end

  context "when antivirus is in progress on pj" do
    let(:types_de_champ_public) { [{ type: :piece_justificative }] }

    before do
      attachment.blob.virus_scan_result = ActiveStorage::VirusScanner::PENDING
    end

    it "does not render" do
      expect(component).not_to be_render
    end
  end

  context "when it's a dossier context" do
    before do
      attachment.created_at = 5.minutes.ago
    end

    let(:component) {
      described_class.new(poll_url: "poll-here", attachment:, context: :dossier)
    }

    it "indicates it's not blocker to submit" do
      expect(subject).to have_content("déposer votre dossier")
    end
  end
end
