# frozen_string_literal: true

describe Champs::PieceJustificativeController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :piece_justificative }]) }
  let(:dossier) { create(:dossier, user: user, procedure: procedure) }
  let(:champ) { dossier.project_champs_public.first }

  describe '#update' do
    render_views
    before { sign_in user }

    subject do
      put :update, params: {
        dossier_id: champ.dossier_id,
        stable_id: champ.stable_id,
        blob_signed_id: file
      }.compact, format: :turbo_stream
    end

    context 'when the file is valid' do
      let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

      it 'attach the file' do
        subject
        champ.reload
        expect(champ.piece_justificative_file.attached?).to be true
        expect(champ.piece_justificative_file[0].filename).to eq('piece_justificative_0.pdf')
      end

      it 'renders the attachment template as Javascript' do
        subject
        expect(response.status).to eq(200)
        expect(response.body).to include("<turbo-stream action=\"replace\" target=\"#{champ.input_group_id}\">")
      end

      it 'updates dossier.last_champ_updated_at' do
        expect { subject }.to change { dossier.reload.last_champ_updated_at }
      end
    end

    context 'when the file is invalid' do
      let(:file) { fixture_file_upload('spec/fixtures/files/invalid_file_format.json', 'bad/bad') }

      it 'doesn’t attach the file' do
        subject
        expect(champ.reload.piece_justificative_file.attached?).to be false
      end

      it 'renders an error' do
        subject
        expect(response.status).to eq(422)
        expect(response.header['Content-Type']).to include('application/json')
        expect(response.parsed_body).to eq({ 'errors' => ['Le champ « Piece justificative file » n’est pas d’un type accepté'] })
      end
    end
  end

  describe '#template' do
    before { freeze_time }

    subject do
      get :template, params: {
        dossier_id: champ.dossier_id,
        stable_id: champ.stable_id
      }
    end

    context "user signed in" do
      before { sign_in user }

      it 'redirects to the template' do
        subject
        expect(response).to redirect_to(champ.type_de_champ.piece_justificative_template.blob)
      end
    end

    context "another user signed in" do
      before { sign_in create(:user) }

      it "should not share template url" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "user anonymous" do
      it 'does not redirect to the template' do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
