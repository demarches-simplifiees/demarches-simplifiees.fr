# frozen_string_literal: true

describe AssignTo, type: :model do
  describe '#procedure_presentation_or_default_and_errors' do
    let(:procedure) { create(:procedure) }
    let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: create(:instructeur)) }

    let(:procedure_presentation_and_errors) { assign_to.procedure_presentation_or_default_and_errors }
    let(:procedure_presentation_or_default) { procedure_presentation_and_errors.first }
    let(:errors) { procedure_presentation_and_errors.second }

    context "without a preexisting procedure_presentation" do
      it 'creates a default pp' do
        expect(procedure_presentation_or_default).to be_persisted
        expect(procedure_presentation_or_default).to be_valid
        expect(errors).to be_nil
      end
    end

    context "with a preexisting procedure_presentation" do
      let!(:procedure_presentation) { ProcedurePresentation.create(assign_to:) }

      it 'returns the preexisting pp' do
        expect(procedure_presentation_or_default).to eq(procedure_presentation)
        expect(procedure_presentation_or_default).to be_valid
        expect(errors).to be_nil
      end
    end

    context "with an invalid procedure_presentation" do
      let!(:procedure_presentation) do
        pp = ProcedurePresentation.create(assign_to: assign_to)

        sql = <<-SQL.squish
          UPDATE procedure_presentations
          SET displayed_columns =  ARRAY['{\"procedure_id\":666}'::jsonb]
          WHERE id = #{pp.id} ;
        SQL

        pp.class.connection.execute(sql)

        assign_to.reload
      end

      it do
        expect(procedure_presentation_or_default).to be_persisted
        expect(procedure_presentation_or_default).to be_valid
        expect(errors.full_messages).to include(/unable to find procedure 666/)
        expect(assign_to.procedure_presentation).not_to be(procedure_presentation)
      end
    end
  end
end
