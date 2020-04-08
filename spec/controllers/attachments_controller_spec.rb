describe AttachmentsController, type: :controller do
  let(:user) { create(:user) }
  let(:attachment) { champ.piece_justificative_file.attachment }
  let(:dossier) { create(:dossier, user: user) }
  let(:champ) { create(:champ_piece_justificative, dossier_id: dossier.id) }
  let(:signed_id) { attachment.blob.signed_id }

  describe '#show' do
    render_views

    let(:format) { :js }

    subject do
      get :show, params: { id: attachment.id, signed_id: signed_id }, format: format
    end

    context 'when authenticated' do
      before { sign_in(user) }

      context 'when requesting Javascript' do
        let(:format) { :js }

        it { is_expected.to have_http_status(200) }

        it 'renders JS that replaces the attachment HTML' do
          subject
          expect(response.body).to have_text(".attachment-link[data-attachment-id=\"#{attachment.id}\"]")
        end
      end

      context 'when the user opens the delete link in a new tab' do
        let(:format) { :html }

        it { is_expected.to have_http_status(302) }
        it { is_expected.to redirect_to(dossier_path(dossier)) }
      end
    end

    context 'when not authenticated' do
      it { is_expected.to have_http_status(401) }
    end
  end

  describe '#destroy' do
    render_views

    let(:attachment) { champ.piece_justificative_file.attachment }
    let(:dossier) { create(:dossier, user: user) }
    let(:champ) { create(:champ_piece_justificative, dossier_id: dossier.id) }
    let(:signed_id) { attachment.blob.signed_id }

    subject do
      delete :destroy, params: { id: attachment.id, signed_id: signed_id }, format: :js
    end

    context "when authenticated" do
      before { sign_in(user) }

      context 'and dossier is owned by user' do
        it { is_expected.to have_http_status(200) }

        it 'removes the attachment' do
          subject
          expect(champ.reload.piece_justificative_file.attached?).to be(false)
        end
      end

      context 'and signed_id is invalid' do
        let(:signed_id) { 'yolo' }

        it { is_expected.to have_http_status(404) }

        it 'doesn’t remove the attachment' do
          subject
          expect(champ.reload.piece_justificative_file.attached?).to be(true)
        end
      end
    end

    context 'when not authenticated' do
      it { is_expected.to have_http_status(401) }

      it 'doesn’t remove the attachment' do
        subject
        expect(champ.reload.piece_justificative_file.attached?).to be(true)
      end
    end
  end
end
