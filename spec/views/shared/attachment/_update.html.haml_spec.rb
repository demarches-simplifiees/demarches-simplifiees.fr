describe 'shared/attachment/_update.html.haml', type: :view do
  let(:champ) { build(:champ_titre_identite, dossier: create(:dossier)) }
  let(:attached_file) { champ.piece_justificative_file }
  let(:user_can_destroy) { false }
  let(:template) { nil }

  subject do
    form_for(champ.dossier) do |form|
      view.render Attachment::EditComponent.new(form: form, attached_file: attached_file, attachment: attached_file[0], user_can_destroy: true, direct_upload: true)
    end
  end

  context 'when there is no attached file' do
    before do
      champ.piece_justificative_file = nil
    end

    it 'renders a form field for uploading a file' do
      expect(subject).to have_selector('input[type=file]:not(.hidden)')
    end
  end

  context 'when there is an attached file' do
    it 'renders a form field for uploading a file' do
      expect(subject).to have_selector('input[type=file]:not(.hidden)')
    end

    it 'does not renders a link to the unsaved file' do
      expect(subject).not_to have_content(attached_file.attachments[0].filename.to_s)
    end

    it 'does not render action buttons' do
      expect(subject).not_to have_link('Supprimer')
    end

    context 'and the attachment has been saved' do
      before { champ.save! }

      it 'renders a link to the file' do
        expect(subject).to have_content(attached_file.attachments[0].filename.to_s)
      end

      it 'hides the form field by default' do
        expect(subject).to have_selector('input[type=file].hidden')
      end

      it 'shows the Delete button by default' do
        is_expected.to have_link('Supprimer')
      end
    end
  end

  context 'when the user cannot destroy the attachment' do
    subject do
      form_for(champ.dossier) do |form|
        render Attachment::EditComponent.new(form: form,
          attached_file: attached_file,
          attachment: attached_file[0],
          user_can_destroy: user_can_destroy,
          direct_upload: true)
      end
    end

    it 'hides the Delete button' do
      is_expected.not_to have_link('Supprimer')
    end
  end
end
