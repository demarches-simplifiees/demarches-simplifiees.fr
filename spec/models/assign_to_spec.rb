describe AssignTo, type: :model do
  describe '#procedure_presentation_or_default_and_errors' do
    let(:procedure) { create(:procedure) }
    let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: create(:instructeur)) }

    let(:procedure_presentation_and_errors) { assign_to.procedure_presentation_or_default_and_errors }
    let(:procedure_presentation_or_default) { procedure_presentation_and_errors.first }
    let(:errors) { procedure_presentation_and_errors.second }

    context "without a procedure_presentation" do
      it { expect(procedure_presentation_or_default).to be_persisted }
      it { expect(procedure_presentation_or_default).to be_valid }
      it { expect(errors).to be_nil }
    end

    context "with a procedure_presentation" do
      let!(:procedure_presentation) { ProcedurePresentation.create(assign_to: assign_to) }

      it { expect(procedure_presentation_or_default).to eq(procedure_presentation) }
      it { expect(procedure_presentation_or_default).to be_valid }
      it { expect(errors).to be_nil }
    end

    context "with an invalid procedure_presentation" do
      let!(:procedure_presentation) do
        pp = ProcedurePresentation.new(assign_to: assign_to, displayed_fields: [{ 'table' => 'invalid', 'column' => 'random' }])
        pp.save(validate: false)
        pp
      end

      it { expect(procedure_presentation_or_default).to be_persisted }
      it { expect(procedure_presentation_or_default).to be_valid }
      it { expect(errors).to be_present }
      it do
        procedure_presentation_or_default
        expect(assign_to.procedure_presentation).not_to be(procedure_presentation)
      end
    end
  end
end
