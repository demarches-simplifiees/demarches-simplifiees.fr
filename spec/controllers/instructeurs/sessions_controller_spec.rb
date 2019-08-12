require 'spec_helper'

describe Instructeurs::SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:instructeur]
  end

  describe '#create' do
    it { expect(described_class).to be < Sessions::SessionsController }
  end
end
