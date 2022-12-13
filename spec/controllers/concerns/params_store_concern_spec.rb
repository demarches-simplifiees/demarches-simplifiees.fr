RSpec.describe ParamsStoreConcern, type: :controller do
  class TestController < ActionController::Base
    include ParamsStoreConcern
  end

  controller TestController do
    def params
      ActionController::Parameters.new(
        controller: "test_controller",
        action: "action",
        param1: "param1",
        param2: "param2"
      )
    end
  end

  describe '#store_params' do
    subject(:store_params) { controller.store_params }

    it "does nothing when params are alread stored" do
      stored_params = "there is alread something in there"
      session[:stored_params] = stored_params

      expect { store_params }.not_to change { session[:stored_params] }
    end

    it "stores current params except controller and action" do
      stored_params = { "param1" => "param1", "param2" => "param2" }.to_json
      expect { store_params }.to change { session[:stored_params] }.from(nil).to(stored_params)
    end
  end

  describe '#stored_params' do
    subject(:stored_params) { controller.stored_params }

    context 'when there are no stored params' do
      it 'returns an empty hash' do
        expect(stored_params).to be_empty
      end
    end

    context 'when params are stored' do
      before { controller.store_params }

      it 'deletes the stored params' do
        expect { stored_params }.to change { session[:stored_params] }.to(nil)
      end

      it 'returns the stored params' do
        expect(stored_params).to eq({ "param1" => "param1", "param2" => "param2" })
      end
    end
  end
end
