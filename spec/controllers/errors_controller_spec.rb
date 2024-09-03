# frozen_string_literal: true

RSpec.describe ErrorsController, type: :controller do
  render_views

  describe 'GET #show' do
    # rspec can't easily manage the exceptions_app for a real route,
    # just verify the action renders correctly
    let(:status_code) { 426 }
    let(:status_message) { 'Upgrade Required' }

    context 'HTML format' do
      subject do
        get :show, params: { status: status_code }, format: :html
      end

      it 'correctly handles and responds with an HTML response' do
        subject
        expect(response).to have_http_status(status_code)
        expect(response.body).to include(status_message)
      end
    end

    context 'JSON format' do
      subject do
        get :show, params: { status: status_code }, format: :json
      end

      it 'correctly handles and responds with a JSON response' do
        subject
        expect(response).to have_http_status(status_code)
        json_response = response.parsed_body

        expect(json_response['status']).to eq(status_code)
        expect(json_response['name']).to eq(status_message)
      end
    end
  end

  shared_examples 'specific action' do
    subject { get action_name }

    it do
      is_expected.to have_http_status(status_code)
    end

    context "404" do
      let(:status_code) { 404 }
      let(:action_name) { :not_found }

      it_behaves_like 'specific action'
    end

    context "422" do
      let(:status_code) { 422 }
      let(:action_name) { :unprocessable_entity }

      it_behaves_like 'specific action'
    end
  end
end
