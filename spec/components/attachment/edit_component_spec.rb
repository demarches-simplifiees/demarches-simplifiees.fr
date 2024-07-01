RSpec.describe Attachment::EditComponent, type: :component do
  let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
  let(:types_de_champ_public) { [{ type: :titre_identite }] }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ) { dossier.champs.first }
  let(:attached_file) { champ.piece_justificative_file }
  let(:attachment) { attached_file.attachments.first }
  let(:filename) { attachment.filename.to_s }
  let(:kwargs) { {} }

  let(:component) do
    described_class.new(
      champ:,
      attached_file:,
      attachment:,
      **kwargs
    )
  end

  subject { render_inline(component).to_html }

  context 'when there is no attachment yet' do
    let(:attachment) { nil }

    it 'renders a form field for uploading a file' do
      expect(subject).to have_selector('input[type=file]:not(.hidden)')
    end

    it 'renders max size' do
      expect(subject).to have_content(/Taille maximale :\s+20 Mo/)
    end

    it 'renders allowed formats' do
      expect(subject).to have_content(/Formats supportés : jpeg, png/)
    end
  end

  context 'when there is an attachment' do
    it 'renders the filename' do
      expect(subject).to have_content(attachment.filename.to_s)
    end

    it 'hides the file field by default' do
      expect(subject).to have_selector('input[type=file].hidden')
    end

    it 'shows the Delete button by default' do
      expect(subject).to have_selector('[title^="Supprimer le fichier"]')
    end
  end

  context 'when the user cannot destroy the attachment' do
    let(:kwargs) { { user_can_destroy: false } }

    it 'hides the Delete button' do
      expect(subject).not_to have_selector("[title^='Supprimer le fichier']")
    end
  end

  context 'within multiple attachments' do
    let(:index) { 0 }
    let(:component) do
      described_class.new(
        champ:,
        attached_file:,
        attachment: nil,
        as_multiple: true,
        index:
      )
    end

    it 'does render an empty file' do # (is is rendered by MultipleComponent)
      expect(subject).to have_selector('input[type=file]')
    end

    it 'renders max size for first index' do
      expect(subject).to have_content(/Taille maximale :\s+20 Mo/)
    end

    context 'when index is not 0' do
      let(:index) { 1 }

      it 'renders max size for first index' do
        expect(subject).not_to have_content('Taille maximale')
      end
    end
  end

  context 'when view as download' do
    let(:kwargs) { { view_as: :download } }

    context 'when watermarking is done' do
      before do
        attachment.blob.touch(:watermarked_at)
      end

      it 'renders a complete downlaod interface with details to download the file' do
        expect(subject).to have_link(text: filename)
        expect(subject).to have_text(/PNG.+\d+ octets/)
      end
    end

    context 'when watermark is pending' do
      it 'displays the filename, but doesn’t allow to download the file' do
        expect(attachment.watermark_pending?).to be_truthy
        expect(subject).to have_text(filename)
        expect(subject).to have_button('Supprimer')
        expect(subject).to have_no_link(text: filename) # don't match "Delete" link which also include filename in title attribute
        expect(subject).to have_text('Traitement en cours')
      end
    end
  end

  context 'when view as link' do
    let(:kwargs) { { view_as: :link } }

    context 'when watermarking is done' do
      before do
        attachment.blob.touch(:watermarked_at)
      end

      it 'renders a simple link to view file' do
        expect(subject).to have_link(text: filename)
        expect(subject).not_to have_text(/PNG.+\d+ octets/)
      end
    end
  end

  context 'with non nominal or final antivirus status' do
    before do
      champ.piece_justificative_file[0].blob.update(virus_scan_result:)
    end

    context 'when the file is scanned, watermarked_at, and viewed as download and safe' do
      let(:kwargs) { { view_as: :download } }
      let(:virus_scan_result) { ActiveStorage::VirusScanner::SAFE }
      before do
        attachment.blob.touch(:watermarked_at)
      end

      it 'allows to download the file' do
        expect(subject).to have_link(filename)
      end
    end

    context 'when the file is scanned and infected' do
      let(:virus_scan_result) { ActiveStorage::VirusScanner::INFECTED }

      it 'displays the filename, but doesn’t allow to download the file' do
        expect(subject).to have_text(champ.piece_justificative_file[0].filename.to_s)
        expect(subject).to have_no_link(text: filename)
        expect(subject).to have_text('Virus détecté')
      end
    end

    context 'when the file is corrupted' do
      let(:virus_scan_result) { ActiveStorage::VirusScanner::INTEGRITY_ERROR }

      it 'displays the filename, but doesn’t allow to download the file' do
        expect(subject).to have_text(filename)
        expect(subject).to have_no_link(text: filename)
        expect(subject).to have_text('corrompu')
      end
    end
  end

  describe 'field name inference' do
    it "by default generate input name directly form attached file object" do
      expect(subject).to have_selector("input[name='champs_titre_identite_champ[piece_justificative_file]']")
    end

    context "when a form object_name is provided" do
      let(:kwargs) { { form_object_name: "my_form" } }

      it "generate input name from form object name and attached file object" do
        expect(subject).to have_selector("input[name='my_form[piece_justificative_file]']")
      end
    end
  end
end
