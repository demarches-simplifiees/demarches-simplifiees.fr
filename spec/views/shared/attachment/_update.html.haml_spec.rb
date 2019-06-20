require 'rails_helper'

describe 'shared/attachment/_update.html.haml', type: :view do
  let(:champ) { build(:champ_piece_justificative, dossier: create(:dossier)) }
  let(:attachment) { nil }
  let(:virus_scan_result) { nil }
  let(:user_can_destroy) { false }

  subject do
    form_for(champ.dossier) do |form|
      render 'shared/attachment/update', {
        attachment: attachment,
        user_can_destroy: user_can_destroy,
        form: form
      }
    end
  end

  it 'renders a form field for uploading a file' do
    expect(subject).to have_selector('input[type=file]:not(.hidden)')
  end

  context 'when there is a attached file' do
    let(:attachment) { champ.piece_justificative_file.attachment }

    it 'renders a form field for uploading a file' do
      expect(subject).to have_selector('input[type=file]:not(.hidden)')
    end

    it 'does not renders a link to the unsaved file' do
      expect(subject).not_to have_content(attachment.filename.to_s)
    end

    it 'doesn’t render action buttons' do
      expect(subject).not_to have_link('Remplacer')
      expect(subject).not_to have_link('Supprimer')
    end

    context 'and the attachment has been saved' do
      before { champ.save! }

      it 'renders a link to the file' do
        expect(subject).to have_content(attachment.filename.to_s)
      end

      it 'renders action buttons' do
        expect(subject).to have_button('Remplacer')
      end

      it 'hides the form field by default' do
        expect(subject).to have_selector('input[type=file].hidden')
      end

      it 'hides the Delete button by default' do
        is_expected.not_to have_link('Supprimer')
      end

      context 'and the user can delete the attachment' do
        let(:user_can_destroy) { true }

        it { is_expected.to have_link('Supprimer') }
      end
    end
  end
end
