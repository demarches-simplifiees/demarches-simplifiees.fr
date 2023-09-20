RSpec.describe Dossiers::ExportLinkComponent, type: :component do
  let(:procedure) { create(:procedure) }
  let(:groupe_instructeur) { create(:groupe_instructeur, procedure: procedure) }
  let(:export) { create(:export, groupe_instructeurs: [groupe_instructeur], updated_at: 5.minutes.ago) }
  let(:export_url) { double("ExportUrl", call: "/some/fake/path") }

  let(:component) { described_class.new(procedure:, exports: [export], export_url:) }

  describe "rendering" do
    subject { render_inline(component).to_html }

    context "when the export is available" do
      before do
        allow(export).to receive(:available?).and_return(true)
        attachment = ActiveStorage::Attachment.new(name: "export", record: export, blob: ActiveStorage::Blob.new(byte_size: 10.kilobytes, content_type: "text/csv", filename: "export.csv"))
        allow(export).to receive(:file).and_return(attachment)
      end

      it "displays the time info" do
        expect(subject).to include("généré il y a 5 minutes")
      end

      it "displays the download button with the correct label" do
        expect(subject).to include("Télécharger")
        expect(subject).to include("CSV")
        expect(subject).to include("10 ko")
      end
    end

    context "when the export is not available" do
      before do
        allow(export).to receive(:available?).and_return(false)
        allow(export).to receive(:failed?).and_return(false)
      end

      it "displays the pending label" do
        expect(subject).to include("demandé il y a 5 minutes")
      end

      it "displays a refresh page button" do
        expect(subject).to include("Recharger")
      end
    end

    context "when the export has failed" do
      before do
        allow(export).to receive(:failed?).and_return(true)
      end

      it "displays the refresh old export button" do
        expect(subject).to include("Regénérer")
      end
    end
  end
end
