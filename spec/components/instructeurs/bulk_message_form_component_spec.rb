# frozen_string_literal: true

describe Instructeurs::BulkMessageFormComponent do
  let(:component) { described_class.new(procedure:, current_instructeur:, dossiers_count_per_groupe_instructeur:) }
  let(:current_instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }

  describe ".default_dossiers_count" do
    subject { component.default_dossiers_count }

    context 'when routing' do
      let(:procedure) { create(:procedure, routing_enabled: true, groupe_instructeurs: [gi_1, gi_2]) }
      let(:dossiers_count_per_groupe_instructeur) do
        {
          nil: 10,
          gi_1.id => 15,
          gi_2.id => 20
        }
      end

      context 'when enabled and instructeur in all groupes' do
        let(:gi_1) { create(:groupe_instructeur, instructeurs: [current_instructeur]) }
        let(:gi_2) { create(:groupe_instructeur, instructeurs: [current_instructeur]) }

        it 'counts all (including count for dossier without groupe instructeur)' do
          expect(subject).to eq(dossiers_count_per_groupe_instructeur.values.sum)
        end
      end

      context 'when enabled and instructeur in groupe' do
        let(:gi_1) { create(:groupe_instructeur, instructeurs: [current_instructeur]) }
        let(:gi_2) { create(:groupe_instructeur, instructeurs: [create(:instructeur)]) }

        it 'counts only dossiers for his groupe_instructeurs' do
          expect(subject).to eq(dossiers_count_per_groupe_instructeur[gi_1.id])
        end
      end
    end

    context 'when routing disabled' do
      let(:procedure) { create(:procedure, routing_enabled: false) }
      let(:dossiers_count_per_groupe_instructeur) do
        {
          nil: 10,
          procedure.groupe_instructeurs.first.id => 15
        }
      end
      it 'counts all (including count for dossier without groupe instructeur)' do
        expect(subject).to eq(dossiers_count_per_groupe_instructeur.values.sum)
      end
    end
  end
end
