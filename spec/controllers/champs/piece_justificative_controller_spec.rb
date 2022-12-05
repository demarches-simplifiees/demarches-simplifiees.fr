describe Champs::PieceJustificativeController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, :published, :with_piece_justificative) }
  let(:dossier) { create(:dossier, user: user, procedure: procedure) }
  let(:champ) { dossier.champs_public.first }

  describe '#update' do
    render_views
    before { sign_in user }

    subject do
      put :update, params: {
        position: '1',
        champ_id: champ.id,
        blob_signed_id: file
      }, format: :turbo_stream
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
        expect(response.body).to include("<turbo-stream action=\"morph\" target=\"#{champ.input_group_id}\">")
      end

      it 'updates dossier.last_champ_updated_at' do
        expect { subject }.to change { dossier.reload.last_champ_updated_at }
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
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['La pièce justificative n’est pas d’un type accepté'] })
      end
    end
  end
end
