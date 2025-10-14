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

        it 'renders turbo_stream that replaces the attachment HTML' do
          is_expected.to have_http_status(200)
          expect(response.body).to include(ActionView::RecordIdentifier.dom_id(attachment, :show))
        end
      end

      context 'when the user opens the delete link in a new tab' do
        let(:format) { :html }

        it do
          is_expected.to have_http_status(302)
          is_expected.to redirect_to(dossier_path(dossier))
        end
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
    let(:view_as) { nil }

    subject do
      delete :destroy, params: { id: attachment.id, signed_id:, dossier_id: dossier&.id, stable_id: champ&.stable_id, view_as: }, format: :turbo_stream
    end

    context "when authenticated" do
      before { sign_in(user) }

      context 'and dossier is owned by user' do
        before { champ.update_columns(external_state: 'fetched', value_json: 'some value') }

        it 'removes the attachment, and resets the ocr data' do
          is_expected.to have_http_status(200)

          champ.reload

          expect(champ.piece_justificative_file.attached?).to be(false)
          expect(champ.external_state).to eq('idle')
          expect(champ.value_json).to be_nil
        end
      end

      context 'and dossier en_construction is owned by user' do
        let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, user:, procedure:) }

        it 'removes the attachment' do
          is_expected.to have_http_status(200)
          expect(user_buffer_champ.piece_justificative_file.attached?).to be(false)
        end
      end

      context 'and signed_id is invalid' do
        let(:signed_id) { 'yolo' }

        it 'doesn’t remove the attachment' do
          is_expected.to have_http_status(404)
          expect(champ.reload.piece_justificative_file.attached?).to be(true)
        end
      end
    end

    context 'as an administrateur' do
      let(:procedure) { create(:procedure, :with_logo) }
      let(:administrateur) { procedure.administrateurs.first }
      let(:attachment) { procedure.logo.attachments.first }
      let(:signed_id) { attachment.blob.signed_id }
      let(:view_as) { 'link' }
      before { sign_in(administrateur.user) }

      context 'when the administrateur owns the procedure' do
        it 'can remove the procedure attachment' do
          is_expected.to have_http_status(200)
          expect(procedure.reload.logo.attached?).to be(false)
        end

        context 'can remove an attestation template attachment' do
          let(:attestation_template) { create(:attestation_template, :with_files) }
          let(:procedure) { attestation_template.procedure }
          let(:attachment) { attestation_template.logo.attachments.first }
          let(:signed_id) { attachment.blob.signed_id }

          it do
            is_expected.to have_http_status(200)
            expect(attestation_template.reload.logo.attached?).to be(false)
          end
        end

        context 'can remove a type de champ notice explicative' do
          let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :text }]) }
          let(:type_de_champ) { procedure.active_revision.types_de_champ.first }
          let(:attachment) { type_de_champ.notice_explicative.attachments.first }
          let(:signed_id) { attachment.blob.signed_id }

          before do
            type_de_champ.notice_explicative.attach({ io: Rails.root.join('spec/fixtures/files/Contrat.pdf').open, filename: 'Notice.pdf' })
          end

          it do
            is_expected.to have_http_status(200)
            expect(type_de_champ.reload.notice_explicative.attached?).to be(false)
          end
        end
      end

      context 'when the administrateur does not own the procedure' do
        let(:administrateur) { create(:administrateur) }

        it 'can remove the procedure attachment' do
          is_expected.to have_http_status(404)
          expect(procedure.reload.logo.attached?).to be(true)
        end
      end
    end

    context 'for an avis' do
      let(:expert) { create(:expert) }
      let(:procedure) { create(:procedure) }
      let(:experts_procedure) { create(:experts_procedure, procedure:, expert:) }
      let(:avis) { create(:avis, dossier:, experts_procedure:) }
      let(:attachment) { avis.piece_justificative_file.attachments.first }
      let(:signed_id) { attachment.blob.signed_id }
      let(:view_as) { 'link' }

      before do
        avis.piece_justificative_file.attach({ io: Rails.root.join('spec/fixtures/files/Contrat.pdf').open, filename: 'Contrat.pdf' })
      end

      context 'when the expert owns the avis' do
        before { sign_in(expert.user) }

        it 'can remove the attachment' do
          is_expected.to have_http_status(200)
          expect(avis.reload.piece_justificative_file.attached?).to be(false)
        end
      end

      context 'when the expert does not own the avis' do
        let(:other_expert) { create(:expert) }
        before { sign_in(other_expert.user) }

        it 'can’t remove the attachment' do
          is_expected.to have_http_status(404)
          expect(avis.reload.piece_justificative_file.attached?).to be(true)
        end
      end
    end

    context 'as an instructeur' do
      let(:instructeur) { create(:instructeur) }
      before { sign_in(instructeur.user) }

      context 'when the instructeur belongs to the procedure' do
        let(:procedure) { create(:procedure, instructeurs: [instructeur], types_de_champ_private: [{ type: :piece_justificative }]) }
        let(:dossier) { create(:dossier, procedure:) }
        let(:champ) do
          dossier.champs.private_only.first.tap do |c|
            c.piece_justificative_file.attach({ io: Rails.root.join('spec/fixtures/files/Contrat.pdf').open, filename: 'Contrat.pdf' })
          end
        end

        it 'remove the attachment' do
          is_expected.to have_http_status(200)
          expect(champ.reload.piece_justificative_file.attached?).to be(false)
        end
      end
    end

    context 'when authenticated as another user' do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it 'doesn’t remove the attachment' do
        is_expected.to have_http_status(404)
        expect(champ.reload.piece_justificative_file.attached?).to be(true)
      end

      context 'when trying to delete an attachment which is not a champ' do
        let(:procedure) { create(:procedure, :with_logo, types_de_champ_public: [{ type: :text }]) }
        let(:attachment) { procedure.logo.attachments.first }
        let(:signed_id) { attachment.blob.signed_id }

        it 'doesn’t remove the attachment' do
          is_expected.to have_http_status(404)
          expect(attachment.reload).to be_present
        end
      end
    end

    context 'when not authenticated' do
      it 'doesn’t remove the attachment' do
        is_expected.to redirect_to(new_user_session_path)
        expect(champ.reload.piece_justificative_file.attached?).to be(true)
      end
    end
  end
end
