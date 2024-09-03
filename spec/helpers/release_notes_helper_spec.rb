# frozen_string_literal: true

RSpec.describe ReleaseNotesHelper, type: :helper do
  describe "#render_release_note_content" do
    let(:release_note) { build(:release_note) }

    it "adds noreferrer, noopener, and target to absolute links" do
      release_note.body = "Go to <a href='http://example.com'>Example</a>"
      processed_content = helper.render_release_note_content(release_note.body)

      expect(processed_content.body.to_s).to include('Go to <a href="http://example.com" rel="noreferrer noopener" target="_blank" title="example.com — Nouvel onglet">Example</a>')
    end

    it "handles content without links" do
      release_note.body = "No links here"
      processed_content = helper.render_release_note_content(release_note.body)

      expect(processed_content.body.to_s).to include("No links here")
    end
  end
end
