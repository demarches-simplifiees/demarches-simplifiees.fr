describe Administrateurs::ExportsController, type: :controller do
  describe '#download' do
    let(:administrateur) { create(:administrateur) }
    before { sign_in(administrateur.user) }

    subject do
      get :download, params: { export_format: :csv, procedure_id: procedure.id }
    end

    context 'when the procedure does not belongs to admin' do
      let!(:procedure) { create(:procedure, administrateurs: [create(:administrateur)]) }
      it 'blocks' do
        is_expected.to have_http_status(:not_found)
      end
    end

    context 'when admin is allowed' do
      let!(:procedure) { create(:procedure, administrateurs: [administrateur]) }

      context 'when the export is does not exist' do
        it 'displays an notice' do
          is_expected.to redirect_to(admin_procedure_archives_url(procedure))
          expect(flash.notice).to be_present
        end

        it { expect { subject }.to change(Export, :count).by(1) }
      end

      context 'when the export is not ready' do
        before do
          create(:export, groupe_instructeurs: procedure.groupe_instructeurs)
        end

        it 'displays an notice' do
          is_expected.to redirect_to(admin_procedure_archives_url(procedure))
          expect(flash.notice).to be_present
        end
      end

      context 'when the export is ready' do
        let(:export) { create(:export, job_status: :generated, groupe_instructeurs: procedure.groupe_instructeurs) }

        before do
          export.file.attach(io: StringIO.new('export'), filename: 'file.csv')
        end

        it 'displays the download link' do
          subject
          expect(response.headers['Location']).to start_with("http://test.host/rails/active_storage/disk")
        end
      end

      context 'when the turbo_stream format is used' do
        before do
          post :download,
            params: { export_format: :csv, procedure_id: procedure.id },
            format: :turbo_stream
        end

        it 'responds in the correct format' do
          expect(response.media_type).to eq('text/vnd.turbo-stream.html')
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'when admin is allowed present as manager' do
      let!(:procedure) { create(:procedure) }
      let!(:administrateur_procedure) { create(:administrateurs_procedure, procedure: procedure, administrateur: administrateur, manager: true) }

      context 'get #index.html' do
        it { is_expected.to have_http_status(:forbidden) }
      end
      context 'get #index.turbo_stream' do
        it 'is forbidden' do
          post :download,
            params: { export_format: :csv, procedure_id: procedure.id },
            format: :turbo_stream
          expect(response).to have_http_status(:forbidden)
        end
      end

    end
  end
end
