describe EmailCheckerController, type: :controller do
  describe '#show' do
    render_views
    before { get :show, format: :json, params: params }
    let(:body) { JSON.parse(response.body, symbolize_names: true) }

    context 'valid email' do
      let(:params) { { email: 'martin@orange.fr' } }
      it do
        expect(response).to have_http_status(:success)
        expect(body).to eq({ success: true })
      end
    end

    context 'email with typo' do
      let(:params) { { email: 'martin@orane.fr' } }
      it do
        expect(response).to have_http_status(:success)
        expect(body).to eq({ success: true, email_suggestions: ['martin@orange.fr'] })
      end
    end

    context 'empty' do
      let(:params) { { email: '' } }
      it do
        expect(response).to have_http_status(:success)
        expect(body).to eq({ success: false })
      end
    end

    context 'notanemail' do
      let(:params) { { email: 'clarkkent' } }
      it do
        expect(response).to have_http_status(:success)
        expect(body).to eq({ success: false })
      end
    end

    context 'incomplete' do
      let(:params) { { email: 'bikram.subedi81@' } }
      it do
        expect(response).to have_http_status(:success)
        expect(body).to eq({ success: false })
      end
    end
  end
end
