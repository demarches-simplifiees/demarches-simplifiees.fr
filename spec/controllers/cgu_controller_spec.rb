require 'spec_helper'

describe CguController, type: :controller do
  describe 'GET #index' do
    subject { get :index }

    it { expect(subject.status).to eq 200 }
  end
end
