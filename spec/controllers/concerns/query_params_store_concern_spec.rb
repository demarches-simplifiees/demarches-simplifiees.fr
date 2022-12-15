RSpec.describe QueryParamsStoreConcern, type: :controller do
  class TestController < ActionController::Base
    include QueryParamsStoreConcern
  end

  controller TestController do
  end

  before { allow_any_instance_of(ActionDispatch::Request).to receive(:query_parameters).and_return(params) }

  describe '#store_query_params' do
    subject(:store_query_params) { controller.store_query_params }

    context 'when params are already stored' do
      let(:params) { { param1: "param1" } }

      it "does nothing" do
        session[:stored_params] = "there is alread something in there"

        expect { store_query_params }.not_to change { session[:stored_params] }
      end
    end

    context 'when params are empty' do
      let(:params) { {} }

      it "does nothing" do
        expect { store_query_params }.not_to change { session[:stored_params] }
      end
    end

    context 'when the store is empty and we have params' do
      let(:params) { { param1: "param1", param2: "param2" } }

      it "stores the query params" do
        expect { store_query_params }.to change { session[:stored_params] }.from(nil).to(params.to_json)
      end
    end
  end

  describe '#retrieve_and_delete_stored_query_params' do
    subject(:retrieve_and_delete_stored_query_params) { controller.retrieve_and_delete_stored_query_params }

    context 'when there are no stored params' do
      let(:params) { {} }

      it 'returns an empty hash' do
        expect(retrieve_and_delete_stored_query_params).to be_empty
      end
    end

    context 'when params are stored' do
      let(:params) { { param1: "param1", param2: "param2" } }

      before { controller.store_query_params }

      it 'deletes the stored params' do
        expect { retrieve_and_delete_stored_query_params }.to change { session[:stored_params] }.to(nil)
      end

      it 'returns the stored params' do
        expect(retrieve_and_delete_stored_query_params).to match(params.with_indifferent_access)
      end
    end
  end
end
