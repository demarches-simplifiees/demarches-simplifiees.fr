require 'spec_helper'

describe DemoController, type: :controller do
  describe 'GET #index' do

    subject { get :index }

    it { expect(subject.status).to eq 200 }

    context 'when rails environnement is production' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      end

      it { expect(subject.status).to eq 302 }
    end
  end
end
