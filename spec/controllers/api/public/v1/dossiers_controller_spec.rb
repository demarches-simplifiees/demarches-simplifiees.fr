RSpec.describe API::Public::V1::DossiersController, type: :controller do
  context 'when the procedure id is present' do
    subject(:create_request) { post :create, params: { procedure_id: procedure.id } }

    shared_examples 'the procedure is not found' do
      before { create_request }

      it { expect(response).to have_http_status(:not_found) }

      it { expect(response).to have_failed_with("procedure #{procedure.id} is not found") }
    end

    context 'when the procedure is found' do
      context 'when the procedure is publiee' do
        context 'when the procedure is opendata' do
          let(:procedure) { create(:procedure, :published, opendata: true) }

          it { expect(create_request).to be_successful }

          # TODO: SEB it { expect { create_request }.to change {Dossier.count}.by(1) }

          # TODO: SEB it { expect(response).to have_http_status(:created) }
        end

        context 'when the procedure is not opendata' do
          it_behaves_like 'the procedure is not found' do
            let(:procedure) { create(:procedure, :published, opendata: false) }
          end
        end
      end

      context 'when the procedure is brouillon' do
        context 'when the procedure is opendata' do
          let(:procedure) { create(:procedure, :draft, opendata: true) }

          it { expect(create_request).to be_successful }

          # TODO: SEB it { expect { create_request }.to change {Dossier.count}.by(1) }

          # TODO: SEB it { expect(response).to have_http_status(:created) }
        end

        context 'when the procedure is not opendata' do
          it_behaves_like 'the procedure is not found' do
            let(:procedure) { create(:procedure, :draft, opendata: false) }
          end
        end
      end

      context 'when the procedure is not publiee and not brouillon' do
        it_behaves_like 'the procedure is not found' do
          let(:procedure) { create(:procedure, :closed) }
        end
      end
    end

    context 'when the procedure is not found' do
      it_behaves_like 'the procedure is not found' do
        let(:procedure) { double(Procedure, id: -1) }
      end
    end
  end

  context 'when the procedure id is blank' do
    subject(:create_request) { post :create }

    before { create_request }

    it { expect(response).to have_http_status(:bad_request) }

    it { expect(response).to have_failed_with("procedure_id is missing") }
  end
end
