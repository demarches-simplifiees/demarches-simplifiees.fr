require 'rails_helper'

RSpec.describe Expert, type: :model do
  describe 'an expert could be add to a procedure' do

    let(:procedure) { create(:procedure) }
    let(:expert) { Expert.create }

    before do
      procedure.experts << expert
      procedure.reload
    end

    it { expect(procedure.experts).to eq([expert]) }
  end
end
