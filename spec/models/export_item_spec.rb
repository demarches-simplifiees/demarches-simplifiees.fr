# frozen_string_literal: true

describe ExportItem do
  describe 'path' do
    let(:export_item) { ExportItem.default(prefix: 'custom') }
    let(:dossier) { create(:dossier) }
    let(:attachment) do
      ActiveStorage::Attachment.new(
        name: 'filename',
        blob: ActiveStorage::Blob.new(filename: "file.pdf")
      )
    end

    context 'without index nor row_index' do
      it do
        expect(export_item.path(dossier, attachment:)).to eq("custom-#{dossier.id}.pdf")
        expect(export_item.path(dossier, attachment:, index: 3)).to eq("custom-#{dossier.id}-04.pdf")
        expect(export_item.path(dossier, attachment:, row_index: 2, index: 3)).to eq("custom-#{dossier.id}-03-04.pdf")
      end
    end
  end
end
