# frozen_string_literal: true

RSpec.describe InstructeursProcedure, type: :model do
  describe '.update_instructeur_procedures_positions' do
    let(:instructeur) { create(:instructeur) }
    let!(:procedures) { create_list(:procedure, 5, published_at: Time.current) }

    before do
      procedures.each_with_index do |procedure, index|
        create(:instructeurs_procedure, instructeur: instructeur, procedure: procedure, position: index + 1)
      end
    end

    it 'updates the positions of the specified instructeurs_procedures' do
      InstructeursProcedure.update_instructeur_procedures_positions(instructeur, procedures.map(&:id))

      updated_positions = InstructeursProcedure
        .where(instructeur:)
        .order(:procedure_id)
        .pluck(:procedure_id, :position)

      expect(updated_positions).to match_array([
        [procedures[0].id, 4],
        [procedures[1].id, 3],
        [procedures[2].id, 2],
        [procedures[3].id, 1],
        [procedures[4].id, 0]
      ])
    end
  end
end
