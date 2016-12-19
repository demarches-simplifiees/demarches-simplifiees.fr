require 'spec_helper'

describe PingController, type: :controller do
  describe 'GET #index' do

    subject { get :index }

    it { expect(subject.status).to eq 200 }

    context 'when base is un-plug' do

      before do
        allow(ActiveRecord::Base).to receive(:connected?).and_return(false)
      end

      it { expect(subject.status).to eq 500 }
    end
  end
end