describe AssignTo, type: :model do
  describe '#procedure_presentation_or_default' do
    let(:procedure) { create(:procedure) }
    let(:assign_to) { AssignTo.create(procedure: procedure) }

    let(:procedure_presentation_or_default) { assign_to.procedure_presentation_or_default }

    context "without a procedure_presentation" do
      it { expect(procedure_presentation_or_default).not_to be_persisted }
    end

    context "with a procedure_presentation" do
      let!(:procedure_presentation) { ProcedurePresentation.create(assign_to: assign_to) }

      it { expect(procedure_presentation_or_default).to eq(procedure_presentation) }
    end
  end
end
