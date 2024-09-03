# frozen_string_literal: true

RSpec.describe Dossiers::ExportLinkComponent, type: :component do
  let(:procedure) { create(:procedure) }
  let(:groupe_instructeur) { create(:groupe_instructeur, procedure: procedure, instructeurs: [build(:instructeur)]) }
  let(:export_url) { double("ExportUrl", call: "/some/fake/path") }

  let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: groupe_instructeur.instructeurs.first) }
  let(:procedure_presentation) { create(:procedure_presentation, procedure: procedure, assign_to: assign_to) }

  let(:component) { described_class.new(procedure:, exports: [export], export_url:) }

  describe "rendering" do
    subject { render_inline(component).to_html }

    context "when the export is available" do
      let(:export) { create(:export, :generated, groupe_instructeurs: [groupe_instructeur], updated_at: 5.minutes.ago, created_at: 10.minutes.ago) }
      before do
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

      context 'when export is for everything' do
        it 'not display the exact dossiers count' do
          expect(subject).to include("tous les dossiers")
        end
      end

      context 'when export is for a presentation' do
        before do
          export.update!(procedure_presentation: procedure_presentation)
        end

        it 'display the persisted dossiers count' do
          expect(subject).to include("10 dossiers")
        end
      end
    end

    context "when the export is not available" do
      let(:export) { create(:export, :pending, groupe_instructeurs: [groupe_instructeur], procedure_presentation: procedure_presentation, created_at: 10.minutes.ago) }

      before do
        create_list(:dossier, 3, :en_construction, procedure: procedure, groupe_instructeur: groupe_instructeur)
      end

      it "displays the pending label" do
        expect(subject).to include("demandé il y a 10 minutes")
      end

      it "displays a refresh page button" do
        expect(subject).to include("Recharger")
      end

      it 'displays the current dossiers count' do
        expect(subject).to include("3 dossiers")
      end

      context "when export is generated, but file not yet available" do
        let(:export) { create(:export, :generated, groupe_instructeurs: [groupe_instructeur], procedure_presentation: procedure_presentation) }

        it "displays the pending label" do
          expect(subject).to include("demandé il y a")
        end
      end
    end

    context "when the export has failed" do
      let(:export) { create(:export, :failed) }

      it "displays the refresh old export button" do
        expect(subject).to include("Regénérer")
      end
    end
  end
end
