# frozen_string_literal: true

RSpec.describe InstructeurProcedureConcern do
  include InstructeurProcedureConcern

  let(:current_instructeur) { create(:instructeur) }

  describe '.ensure_instructeur_procedures_for' do
    let!(:procedures) { create_list(:procedure, 5, :published) }

    context 'when some procedures are missing for the instructeur' do
      before do
        create(:instructeurs_procedure, instructeur: current_instructeur, procedure: procedures.first, position: 0, last_revision_seen_id: procedures.first.published_revision_id)
      end

      it 'creates missing instructeurs_procedures with correct attributes' do
        expect {
          ensure_instructeur_procedures_for(procedures)
        }.to change { InstructeursProcedure.count }.by(4)

        instructeur_procedures = InstructeursProcedure.where(instructeur: current_instructeur)
        expect(instructeur_procedures.pluck(:procedure_id)).to match_array(procedures.map(&:id))
        expect(instructeur_procedures.pluck(:position)).to eq([0, 1, 2, 3, 4])
        expect(instructeur_procedures.pluck(:last_revision_seen_id)).to match_array(procedures.map(&:published_revision_id))
      end
    end

    context 'when all procedures already exist for the instructeur' do
      before do
        procedures.each_with_index do |procedure, index|
          create(:instructeurs_procedure, instructeur: current_instructeur, procedure: procedure, position: index + 1)
        end
      end

      it 'does not create any new instructeurs_procedures' do
        expect {
          ensure_instructeur_procedures_for(procedures)
        }.not_to change { InstructeursProcedure.count }
      end
    end
  end

  describe '.find_or_create_instructeur_procedure' do
    let(:procedure) { create(:procedure, :published) }

    context "when the instructeurs_procedure already exist" do
      let!(:instructeur_procedure) { create(:instructeurs_procedure, instructeur: current_instructeur, procedure:, position: 0, last_revision_seen_id: procedure.published_revision_id) }

      it 'does not create any new instructeurs_procedures' do
        expect {
          find_or_create_instructeur_procedure(procedure)
        }.not_to change { InstructeursProcedure.count }
      end
    end

    context "when the instructeurs_procedure does not exist" do
      it "create an instructeurs_procedure with correct attributes" do
        expect {
          find_or_create_instructeur_procedure(procedure)
        }.to change { InstructeursProcedure.count }.by(1)

        instructeur_procedure = InstructeursProcedure.first
        expect(instructeur_procedure.position).to eq(1)
        expect(instructeur_procedure.last_revision_seen_id).to eq(procedure.published_revision_id)
      end
    end
  end
end
