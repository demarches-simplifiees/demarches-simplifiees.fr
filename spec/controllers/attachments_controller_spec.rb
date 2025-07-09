# frozen_string_literal: true

describe AttachmentsController, type: :controller do
  let(:user) { create(:user) }
  let(:attachment) { champ.piece_justificative_file.attachments.first }
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
  let(:dossier) { create(:dossier, :with_populated_champs, user:, procedure:) }
  let(:champ) { dossier.champs.first }
  let(:user_buffer_champ) { dossier.champs.reload.find(&:user_buffer_stream?) }
  let(:signed_id) { attachment.blob.signed_id }

  before { Flipper.enable(:user_buffer_stream, procedure) }

  describe '#show' do
    render_views

    let(:format) { :turbo_stream }

    subject do
      request.headers['HTTP_REFERER'] = dossier_url(dossier)
      get :show, params: { id: attachment.id, signed_id: signed_id }, format: format
    end

    context 'when authenticated' do
      before { sign_in(user) }

      context 'when requesting turbo_stream' do
        let(:format) { :turbo_stream }

        it { is_expected.to have_http_status(200) }

        it 'renders turbo_stream that replaces the attachment HTML' do
          subject
          expect(response.body).to include(ActionView::RecordIdentifier.dom_id(attachment, :show))
        end
      end

      context 'when the user opens the delete link in a new tab' do
        let(:format) { :html }

        it { is_expected.to have_http_status(302) }
        it { is_expected.to redirect_to(dossier_path(dossier)) }
      end
    end

    context 'when not authenticated' do
      it { is_expected.to redirect_to(new_user_session_path) }
    end
  end

  describe '#destroy' do
    render_views

    let(:attachment) { champ.piece_justificative_file.attachments.first }
    let(:signed_id) { attachment.blob.signed_id }

    subject do
      delete :destroy, params: { id: attachment.id, signed_id: signed_id, dossier_id: dossier.id, stable_id: champ.stable_id }, format: :turbo_stream
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

      context 'and dossier en_construction is owned by user' do
        let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, user:, procedure:) }
        it { is_expected.to have_http_status(200) }

        it 'removes the attachment' do
          subject
          expect(user_buffer_champ.piece_justificative_file.attached?).to be(false)
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
      it { is_expected.to redirect_to(new_user_session_path) }

      it 'doesn’t remove the attachment' do
        subject
        expect(champ.reload.piece_justificative_file.attached?).to be(true)
      end
    end
  end
end
