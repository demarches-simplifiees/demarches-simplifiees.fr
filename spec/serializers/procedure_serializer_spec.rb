describe ProcedureSerializer do
  describe '#attributes' do
    subject { ProcedureSerializer.new(procedure).serializable_hash }
    let(:procedure) { create(:procedure, :published) }

    it {
      is_expected.to include(link: "http://localhost:3000/commencer/#{procedure.path}")
    }
  end
end
