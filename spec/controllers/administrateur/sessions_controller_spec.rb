require 'spec_helper'

describe Administrateurs::SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:administrateur]
  end

  describe '.demo' do
    subject { get :demo }

    context 'when rails env is production' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      end

      it { is_expected.to redirect_to root_path }
    end

    context 'when rails env is not production' do
      it { expect(subject.status).to eq 200 }

      it 'Administrateur demo is initiated' do
        expect(Administrateur).to receive(:new).with(email: 'admin@tps.fr', password: 'password').and_return(Administrateur)
        subject
      end
    end
  end

  describe '.create' do
    it { expect(described_class).to be < Sessions::SessionsController }
  end
end