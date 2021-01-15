RSpec.describe Expert, type: :model do
  describe 'an expert could be add to a procedure' do
    let(:procedure) { create(:procedure) }
    let(:expert) { create(:expert) }

    before do
      procedure.experts << expert
      procedure.reload
    end

    it { expect(procedure.experts).to eq([expert]) }
    it { expect(ExpertsProcedure.where(expert: expert, procedure: procedure).count).to eq(1) }
    it { expect(ExpertsProcedure.where(expert: expert, procedure: procedure).first.allow_decision_access).to be_falsy }
  end
end
