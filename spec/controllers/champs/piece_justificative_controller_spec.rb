describe Champs::PieceJustificativeController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, :with_instructeur, types_de_champ_public: [{ type: :piece_justificative }], types_de_champ_private: [{ type: :piece_justificative }]) }
  let(:dossier) { create(:dossier, user: user, procedure: procedure) }
  let(:champ) { dossier.champs_public.first }

  describe '#download' do
    let(:instructeur) { procedure.defaut_groupe_instructeur.instructeurs.first }
    let(:annotation) { dossier.champs_private.first }
    before do
      sign_in instructeur.user
      put :update, params: {
        position: '1',
        champ_id: annotation.id,
        blob_signed_id: file
      }, format: 'turbo_stream'
      sign_out instructeur.user
      sign_in current_user
    end

    let(:params) do
      annotation.reload
      {
        champ_id: annotation.id.to_s,
        h: annotation.encoded_date(:created_at),
        i: 0
      }
    end

    subject do
      get :download, params: params
    end

    shared_examples_for "he can download qrcoded pdf" do
      it 'it should be able to download a qrcoded pdf' do
        subject
        expect(response.status).to eq(200) # generated pdfs
      end
    end

    shared_examples_for "he can download original pdf" do
      it 'he should be able to download original pdf' do
        subject
        expect(response.status).to eq(302)
        expect(response.location).to include('active_storage')
      end
    end

    shared_examples_for "he can't download pdf" do
      it "it shouldn't be able to download a qrcoded pdf" do
        subject
        expect(response.status).to eq(400)
        expect(response.location).to eq("http://test.host/")
      end
    end

    [false, true].each do |value|
      before do
        if value
          Flipper.enable(:champ_update_by_stable_id)
        else
          Flipper.disable(:champ_update_by_stable_id)
        end
      end

      context 'when user wants to download pdf piece_justificative,' do
        let(:current_user) { user }
        let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

        context 'when procedure qrcoding is not activated,' do
          before { Flipper.disable(:qrcoded_pdf, procedure) }
          it_behaves_like "he can download original pdf"
        end

        context 'when procedure qrcoding is activated,' do
          before { Flipper.enable(:qrcoded_pdf, procedure) }
          it_behaves_like "he can download qrcoded pdf"

          context 'when created_date is wrong' do
            let(:params) { { champ_id: annotation.id.to_s, h: 'x' } }
            it_behaves_like "he can't download pdf"
          end
        end

        context 'using legacy link' do
          subject do
            params.delete(:i)
            get :show, params: params
          end

          it 'is redirected to download url' do
            subject
            expect(response.status).to eq(302)
            expect(response.location).to include("#{params[:champ_id]}/piece_justificative/download/#{params[:h]}")
          end
        end
      end

      context 'when instructeur wants to download pdf piece_justificative,' do
        let(:current_user) { instructeur.user }
        let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

        context 'when procedure qrcoding is not activated,' do
          before { Flipper.disable(:qrcoded_pdf, procedure) }
          it_behaves_like "he can download original pdf"
        end

        context 'when procedure qrcoding is activated,' do
          before { Flipper.enable(:qrcoded_pdf, procedure) }
          it_behaves_like "he can download qrcoded pdf"

          context 'when created_date is wrong,' do
            let(:params) { { champ_id: annotation.id.to_s, h: 'x' } }
            it_behaves_like "he can't download pdf"
          end
        end
      end

      context 'when Another User wants to download pdf piece_justificative,' do
        let(:current_user) { create(:user) }
        let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

        context 'when procedure qrcoding is not activated,' do
          before { Flipper.disable(:qrcoded_pdf, procedure) }
          it_behaves_like "he can download original pdf"
        end

        context 'when procedure qrcoding is activated,' do
          before { Flipper.enable(:qrcoded_pdf, procedure) }
          it_behaves_like "he can download qrcoded pdf"
        end

        context 'when created_date is wrong,' do
          let(:params) { { champ_id: annotation.id.to_s, h: 'x' } }
          before { Flipper.enable(:qrcoded_pdf, procedure) }
          it_behaves_like "he can't download pdf"
        end
      end
    end
  end

  describe '#update' do
    render_views
    before { sign_in user }

    subject do
      put :update, params: {
        position: '1',
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

      it 'does not create a champ_revision' do
        expect(ChampRevision.where(champ_id: champ.id).first).to eq(nil)
      end

      context 'when the champ is private' do
        let(:champ) { dossier.champs_private.first }
        let(:instructeur) { create(:instructeur) }
        let(:procedure) { create(:procedure, :published, :with_instructeur, types_de_champ_public: [{ type: :piece_justificative }], types_de_champ_private: [{ type: :piece_justificative }], instructeurs: [instructeur]) }

        before { sign_in instructeur.user }

        it 'create a champ_revision' do
          subject

          expect(ChampRevision.where(champ_id: champ.id).first.instructeur_id).to eq(instructeur.id)
        end
      end
    end

    context 'when the file is invalid' do
      let(:file) { fixture_file_upload('spec/fixtures/files/invalid_file_format.json', 'application/json') }

      # TODO: for now there are no validators on the champ piece_justificative_file,
      # so we have to mock a failing validation.
      # Once the validators will be enabled, remove those mocks, and let the usual
      # validation fail naturally.
      #
      # See https://github.com/betagouv/demarches-simplifiees.fr/issues/4926
      before do
        champ
        expect_any_instance_of(Champs::PieceJustificativeChamp).to receive(:save).twice.and_return(false)
        expect_any_instance_of(Champs::PieceJustificativeChamp).to receive(:errors)
          .and_return(double(full_messages: ['La pièce justificative n’est pas d’un type accepté']))
      end

      it 'doesn’t attach the file' do
        subject
        expect(champ.reload.piece_justificative_file.attached?).to be false
      end

      it 'renders an error' do
        subject
        expect(response.status).to eq(422)
        expect(response.header['Content-Type']).to include('application/json')
        expect(response.parsed_body).to eq({ 'errors' => ['La pièce justificative n’est pas d’un type accepté'] })
      end
    end
  end

  describe '#template' do
    before { Timecop.freeze }
    after { Timecop.return }

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
