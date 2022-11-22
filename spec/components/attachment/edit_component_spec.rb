RSpec.describe Attachment::EditComponent, type: :component do
  let(:champ) { create(:champ_titre_identite, dossier: create(:dossier)) }
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
      expect(subject).to have_content(/Formats supportés :\s+jpeg, png/)
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

    it 'does not render an empty file' do # (is is rendered by MultipleComponent)
      expect(subject).not_to have_selector('input[type=file]')
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

  context 'when user can download' do
    let(:kwargs) { { user_can_download: true } }

    it 'renders a link to download the file' do
      expect(subject).to have_link(filename)
    end

    context 'when watermark is pending' do
      let(:champ) { create(:champ_titre_identite) }
      let(:kwargs) { { user_can_download: true } }

      it 'displays the filename, but doesn’t allow to download the file' do
        expect(attachment.watermark_pending?).to be_truthy
        expect(subject).to have_text(filename)
        expect(subject).to have_link('Supprimer')
        expect(subject).to have_no_link(text: filename) # don't match "Delete" link which also include filename in title attribute
        expect(subject).to have_text('Traitement en cours')
      end
    end
  end

  context 'with non nominal or final antivirus status' do
    before do
      champ.piece_justificative_file[0].blob.update(metadata: attachment.blob.metadata.merge(virus_scan_result: virus_scan_result))
    end

    context 'when the anti-virus scan is pending' do
      let(:virus_scan_result) { ActiveStorage::VirusScanner::PENDING }

      it 'displays the filename, but doesn’t allow to download the file' do
        expect(subject).to have_text(filename)
        expect(subject).to have_no_link(text: filename)
        expect(subject).to have_text('Analyse antivirus en cours')
      end

      it 'setup polling' do
        expect(subject).to have_selector('[data-controller=turbo-poll]')
      end

      context "process is taking longer than expected" do
        before do
          champ.piece_justificative_file.attachments[0].update!(created_at: 5.minutes.ago)
        end

        it 'renders a refresh button' do
          expect(subject).to have_button("Rafraîchir")
        end
      end

      context "when used as multiple context" do
        let(:kwargs) { { as_multiple: true } }

        it 'does not setup polling' do
          expect(subject).to have_no_selector('[data-controller=turbo-poll]')
        end
      end
    end

    context 'when the file is scanned and safe' do
      let(:virus_scan_result) { ActiveStorage::VirusScanner::SAFE }

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
end
