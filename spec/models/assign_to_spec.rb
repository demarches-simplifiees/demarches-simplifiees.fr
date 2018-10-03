describe AssignTo, type: :model do
  describe '#procedure_presentation_or_default' do
    context "without a procedure_presentation" do
      let!(:assign_to) { AssignTo.create }

      it { expect(assign_to.procedure_presentation_or_default.persisted?).to be_falsey }
    end

    context "with a procedure_presentation" do
      let(:procedure) { create(:procedure) }
      let!(:assign_to) { AssignTo.create(procedure: procedure) }
      let!(:procedure_presentation) { ProcedurePresentation.create(assign_to: assign_to) }

      it { expect(assign_to.procedure_presentation_or_default).to eq(procedure_presentation) }
    end
  end
end
