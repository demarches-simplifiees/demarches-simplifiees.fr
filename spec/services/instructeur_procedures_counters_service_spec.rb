# frozen_string_literal: true

describe InstructeursProceduresCountersService do
  let(:instructeur) { instructeurs(:default_instructeur_admin) }

  describe '#call' do
    subject { described_class.new(instructeur:, procedures: instructeur.procedures).call }

    context "with dossiers" do
      let(:procedure) { create(:procedure, :published, :expirable) }

      before do
        instructeur.groupe_instructeurs << procedure.defaut_groupe_instructeur
      end

      context "with not draft state on multiple procedures" do
        let(:procedure2) { create(:procedure, :published, :expirable) }
        let(:procedure3) { create(:procedure, :closed, :expirable) }
        let(:procedure4) { create(:procedure, :closed, :expirable) }

        before do
          create_list(:dossier, 2, procedure:, state: Dossier.states.fetch(:en_construction))
          create(:dossier, procedure:, state: Dossier.states.fetch(:en_construction), hidden_by_user_at: 1.hour.ago)
          create(:dossier, procedure:, state: Dossier.states.fetch(:en_instruction))

          create(:dossier, procedure:, state: Dossier.states.fetch(:sans_suite), archived: true)
          create(:dossier, procedure:, state: Dossier.states.fetch(:sans_suite), archived: true,
                          hidden_by_administration_at: 1.day.ago)

          instructeur.groupe_instructeurs << procedure2.defaut_groupe_instructeur
          create(:dossier, :followed, procedure: procedure2, state: Dossier.states.fetch(:en_construction))
          create(:dossier, procedure: procedure2, state: Dossier.states.fetch(:accepte))
          instructeur.followed_dossiers << create(:dossier, procedure: procedure2, state: Dossier.states.fetch(:en_instruction))

          create(:dossier, procedure:, state: Dossier.states.fetch(:sans_suite),
                          processed_at: 8.months.ago).tap(&:update_expired_at) # counted as expirable
          create(:dossier, procedure:, state: Dossier.states.fetch(:sans_suite),
                          processed_at: 8.months.ago,
                          hidden_by_administration_at: 1.day.ago) # not counted as expirable since its removed by instructeur
          create(:dossier, procedure:, state: Dossier.states.fetch(:sans_suite),
                          processed_at: 8.months.ago,
                          hidden_by_user_at: 1.day.ago).tap(&:update_expired_at) # counted as expirable because even if user remove it, instructeur see it

          instructeur.groupe_instructeurs << procedure3.defaut_groupe_instructeur
          create(:dossier, :followed, procedure: procedure3, state: Dossier.states.fetch(:en_construction))
          create(:dossier, procedure: procedure3, state: Dossier.states.fetch(:sans_suite))

          instructeur.groupe_instructeurs << procedure4.defaut_groupe_instructeur
          create(:dossier, procedure: procedure4, state: Dossier.states.fetch(:sans_suite))
        end

        it "counts dossiers" do
          expect(subject.dossiers_count_per_procedure[procedure.id]).to eq(5)
          expect(subject.dossiers_a_suivre_count_per_procedure[procedure.id]).to eq(3)
          expect(subject.followed_dossiers_count_per_procedure[procedure.id]).to eq(nil)
          expect(subject.dossiers_termines_count_per_procedure[procedure.id]).to eq(2)
          expect(subject.dossiers_expirant_count_per_procedure[procedure.id]).to eq(2)

          expect(subject.dossiers_count_per_procedure[procedure2.id]).to eq(3)
          expect(subject.dossiers_a_suivre_count_per_procedure[procedure2.id]).to eq(nil)
          expect(subject.followed_dossiers_count_per_procedure[procedure2.id]).to eq(1)
          expect(subject.dossiers_termines_count_per_procedure[procedure2.id]).to eq(1)

          expect(subject.dossiers_count_per_procedure[procedure3.id]).to eq(2)

          expect(subject.all_dossiers_counts['a-suivre']).to eq(3 + 0)
          expect(subject.all_dossiers_counts['suivis']).to eq(0 + 1)
          expect(subject.all_dossiers_counts['traites']).to eq(2 + 1 + 1 + 1)
          expect(subject.all_dossiers_counts['tous']).to eq(5 + 3 + 2 + 1)
          expect(subject.all_dossiers_counts['expirant']).to eq(2 + 0)
        end
      end

      context 'with not draft state on discarded procedure' do
        let(:discarded_procedure) { create(:procedure, :discarded, :expirable) }
        let(:state) { Dossier.states.fetch(:en_construction) }

        before do
          create(:dossier, procedure:, state: Dossier.states.fetch(:en_construction))
          create(:dossier, procedure: discarded_procedure, state: Dossier.states.fetch(:en_construction))
          instructeur.groupe_instructeurs << discarded_procedure.defaut_groupe_instructeur
        end

        it "counts dossiers" do
          expect(subject.dossiers_count_per_procedure[procedure.id]).to eq(1)
          expect(subject.dossiers_a_suivre_count_per_procedure[procedure.id]).to eq(1)
          expect(subject.dossiers_count_per_procedure[discarded_procedure.id]).to be_nil
          expect(subject.all_dossiers_counts['a-suivre']).to eq(1)
        end
      end

      context "with a routed procedure" do
        let!(:gi_default) { procedure.defaut_groupe_instructeur }
        let!(:gi_2) { GroupeInstructeur.create(label: '2', procedure:) }

        context 'with multiple dossiers en construction on each group' do
          before do
            alternate_gis = 0.upto(20).map { |i| i.even? ? gi_default : gi_2 }

            alternate_gis.take(4).each { |gi| create(:dossier, procedure:, state: Dossier.states.fetch(:en_construction), groupe_instructeur: gi) }

            alternate_gis.take(6).each do |gi|
              instructeur.followed_dossiers << create(:dossier, procedure:, state: Dossier.states.fetch(:en_instruction), groupe_instructeur: gi)
            end

            alternate_gis.take(10).each { |gi| create(:dossier, procedure:, state: Dossier.states.fetch(:sans_suite), groupe_instructeur: gi) }
            alternate_gis.take(14).each { |gi| create(:dossier, procedure:, state: Dossier.states.fetch(:sans_suite), groupe_instructeur: gi, archived: true) }
          end

          context 'when an instructeur only belongs to one of them gi' do
            it "counts dossiers" do
              expect(subject.dossiers_a_suivre_count_per_procedure[procedure.id]).to eq(2)

              # An instructeur cannot follow a dossier which belongs to another groupe
              expect(subject.followed_dossiers_count_per_procedure[procedure.id]).to eq(3)
              expect(subject.dossiers_termines_count_per_procedure[procedure.id]).to eq(5)
              expect(subject.dossiers_count_per_procedure[procedure.id]).to eq(2 + 3 + 5)

              expect(subject.all_dossiers_counts['a-suivre']).to eq(2)
              expect(subject.all_dossiers_counts['suivis']).to eq(3)
              expect(subject.all_dossiers_counts['traites']).to eq(5)
              expect(subject.all_dossiers_counts['tous']).to eq(2 + 3 + 5)

              expect(subject.groupes_instructeurs_ids).to eq([gi_default.id])
            end
          end

          context 'when instructeur also belongs to a second groupe' do
            before do
              instructeur.groupe_instructeurs << gi_2
            end

            it "counts dossiers" do
              expect(subject.dossiers_a_suivre_count_per_procedure[procedure.id]).to eq(4)
              expect(subject.followed_dossiers_count_per_procedure[procedure.id]).to eq(6)
              expect(subject.dossiers_termines_count_per_procedure[procedure.id]).to eq(10)
              expect(subject.dossiers_count_per_procedure[procedure.id]).to eq(4 + 6 + 10)

              expect(subject.all_dossiers_counts['a-suivre']).to eq(4)
              expect(subject.all_dossiers_counts['suivis']).to eq(6)
              expect(subject.all_dossiers_counts['traites']).to eq(10)
              expect(subject.all_dossiers_counts['tous']).to eq(4 + 6 + 10)

              expect(subject.groupes_instructeurs_ids).to match_array([gi_default.id, gi_2.id])
            end
          end
        end
      end
    end
  end
end
