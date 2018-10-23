describe AssignTo, type: :model do
  describe '#procedure_presentation_or_default_and_errors' do
    let(:procedure) { create(:procedure) }
    let(:assign_to) { AssignTo.create(procedure: procedure) }

    let(:procedure_presentation_and_errors) { assign_to.procedure_presentation_or_default_and_errors }
    let(:procedure_presentation_or_default) { procedure_presentation_and_errors.first }
    let(:errors) { procedure_presentation_and_errors.second }

    context "without a procedure_presentation" do
      it { expect(procedure_presentation_or_default).not_to be_persisted }
      it { expect(errors).to be_nil }
    end

    context "with a procedure_presentation" do
      let!(:procedure_presentation) { ProcedurePresentation.create(assign_to: assign_to) }

      it { expect(procedure_presentation_or_default).to eq(procedure_presentation) }
      it { expect(errors).to be_nil }
    end
  end
end
