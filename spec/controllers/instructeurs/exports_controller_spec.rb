describe Instructeurs::ExportsController, type: :controller do
  describe '#index' do
    let(:instructeur) { create(:instructeur) }
    let!(:procedure) { create(:procedure) }
    let!(:gi_0) { procedure.defaut_groupe_instructeur }
    let!(:gi_1) { create(:groupe_instructeur, label: 'gi_1', procedure: procedure, instructeurs: [instructeur]) }

    before { sign_in(instructeur.user) }

    subject do
      get :index, params: { export_format: :csv, procedure_id: procedure.id }
    end

    context 'when the export is does not exist' do
      it 'displays an notice' do
        is_expected.to redirect_to(instructeur_procedure_url(procedure))
        expect(flash.notice).to be_present
      end

      it { expect { subject }.to change(Export, :count).by(1) }
    end

    context 'when the export is not ready' do
      before do
        create(:export, groupe_instructeurs: [gi_1])
      end

      it 'displays an notice' do
        is_expected.to redirect_to(instructeur_procedure_url(procedure))
        expect(flash.notice).to be_present
      end
    end

    context 'when the export is ready' do
      let(:export) { create(:export, groupe_instructeurs: [gi_1]) }

      before do
        export.file.attach(io: StringIO.new('export'), filename: 'file.csv')
      end

      it 'displays the download link' do
        subject
        expect(response.headers['Location']).to start_with("http://test.host/rails/active_storage/disk")
      end
    end

    context 'when another export is ready' do
      let(:export) { create(:export, groupe_instructeurs: [gi_0, gi_1]) }

      before do
        export.file.attach(io: StringIO.new('export'), filename: 'file.csv')
      end

      it 'displays an notice' do
        is_expected.to redirect_to(instructeur_procedure_url(procedure))
        expect(flash.notice).to be_present
      end
    end

    context 'when the turbo_stream format is used' do
      before do
        post :index,
          params: { export_format: :csv, procedure_id: procedure.id },
          format: :turbo_stream
      end

      it 'responds in the correct format' do
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
