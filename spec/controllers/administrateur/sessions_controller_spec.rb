require 'spec_helper'

describe Administrateurs::SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:administrateur]
  end

  describe '.create' do
    it { expect(described_class).to be < Sessions::SessionsController }
  end
end