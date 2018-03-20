require 'spec_helper'

describe Gestionnaires::SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:gestionnaire]
  end

  describe '#create' do
    it { expect(described_class).to be < Sessions::SessionsController }
  end
end
