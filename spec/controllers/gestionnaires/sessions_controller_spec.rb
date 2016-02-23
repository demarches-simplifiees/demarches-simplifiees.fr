require 'spec_helper'

describe Gestionnaires::SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:gestionnaire]
  end

  describe '.demo' do
    context 'when server is on env production' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      end
      subject { get :demo }

      it { expect(subject).to redirect_to root_path }

    end
  end

  describe '.create' do
    it { expect(described_class).to be < Sessions::SessionsController }
  end
end