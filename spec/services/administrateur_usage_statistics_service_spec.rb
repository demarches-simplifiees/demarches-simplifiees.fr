require 'spec_helper'

describe AdministrateurUsageStatisticsService do
  describe '#administrateur_stats' do
    let(:service) { AdministrateurUsageStatisticsService.new }
    subject { service.send(:administrateur_stats, administrateur) }

    before { Timecop.freeze(Time.zone.now) }
    after { Timecop.return }

    context 'for an administrateur that has nothing' do
      let(:administrateur) { create(:administrateur) }

      it do
        is_expected.to eq(
          ds_sign_in_count: 0,
          ds_created_at: Time.zone.now,
          ds_active: false,
          ds_id: administrateur.id,
          ds_features: "{}",
          nb_services: 0,
          nb_instructeurs: 0,
          ds_nb_demarches_actives: 0,
          ds_nb_demarches_archives: 0,
          ds_nb_demarches_brouillons: 0,
          nb_demarches_test: 0,
          nb_demarches_prod: 0,
          nb_demarches_prod_20: 0,
          nb_dossiers: 0,
          nb_dossiers_max: 0,
          nb_dossiers_traite: 0,
          nb_dossiers_dossier_en_instruction: 0
        )
      end
    end

    context 'for an administrateur that has plenty of things' do
      let(:administrateur) do
        create(:administrateur,
          sign_in_count: 17,
          current_sign_in_at: Time.zone.local(2019, 3, 7),
          last_sign_in_at: Time.zone.local(2019, 2, 27),
          active: true,
          features: { holy_hand_grenade_of_antioch: true },
          services: [create(:service)],
          gestionnaires: [create(:gestionnaire)])
      end

      it do
        is_expected.to include(
          ds_sign_in_count: 17,
          ds_current_sign_in_at: Time.zone.local(2019, 3, 7),
          ds_last_sign_in_at: Time.zone.local(2019, 2, 27),
          ds_created_at: Time.zone.now,
          ds_active: true,
          ds_id: administrateur.id,
          ds_features: { holy_hand_grenade_of_antioch: true }.to_json,
          nb_services: 1,
          nb_instructeurs: 1
        )
      end
    end

    context 'counting procedures and dossiers' do
      let(:administrateur) do
        create(:administrateur, procedures: [procedure])
      end

      context 'with a freshly active procedure' do
        let(:procedure) { create(:procedure, aasm_state: 'publiee') }

        it do
          is_expected.to include(
            ds_nb_demarches_actives: 1,
            ds_nb_demarches_archives: 0,
            ds_nb_demarches_brouillons: 0,
            nb_demarches_test: 0,
            nb_demarches_prod: 0,
            nb_demarches_prod_20: 0,
            nb_dossiers: 0,
            nb_dossiers_max: 0,
            nb_dossiers_traite: 0,
            nb_dossiers_dossier_en_instruction: 0
          )
        end
      end

      context 'with a procedure archivee' do
        let(:procedure) { create(:procedure, aasm_state: 'archivee', dossiers: dossiers) }
        let(:dossiers) do
          (1..7).flat_map do
            [
              create(:dossier, :en_construction),
              create(:dossier, :en_instruction),
              create(:dossier, :accepte)
            ]
          end
        end

        it do
          is_expected.to include(
            ds_nb_demarches_actives: 0,
            ds_nb_demarches_archives: 1,
            ds_nb_demarches_brouillons: 0,
            nb_demarches_test: 0,
            nb_demarches_prod: 1,
            nb_demarches_prod_20: 1,
            nb_dossiers: 21,
            nb_dossiers_max: 21,
            nb_dossiers_traite: 7,
            nb_dossiers_dossier_en_instruction: 7
          )
        end
      end

      context 'with a procedure brouillon' do
        let(:procedure) { create(:procedure) }

        it do
          is_expected.to include(
            ds_nb_demarches_actives: 0,
            ds_nb_demarches_archives: 0,
            ds_nb_demarches_brouillons: 1,
            nb_demarches_test: 0,
            nb_demarches_prod: 0,
            nb_demarches_prod_20: 0,
            nb_dossiers: 0,
            nb_dossiers_max: 0,
            nb_dossiers_traite: 0,
            nb_dossiers_dossier_en_instruction: 0
          )
        end
      end

      context 'with a procedure en test' do
        let(:procedure) { create(:procedure, dossiers: dossiers) }
        let(:dossiers) do
          (1..7).flat_map do
            [
              create(:dossier, :en_construction),
              create(:dossier, :en_instruction),
              create(:dossier, :accepte)
            ]
          end
        end

        it do
          is_expected.to include(
            ds_nb_demarches_actives: 0,
            ds_nb_demarches_archives: 0,
            ds_nb_demarches_brouillons: 1,
            nb_demarches_test: 1,
            nb_demarches_prod: 0,
            nb_demarches_prod_20: 0,
            nb_dossiers: 0,
            nb_dossiers_max: 0,
            nb_dossiers_traite: 0,
            nb_dossiers_dossier_en_instruction: 0
          )
        end
      end

      context 'with a procedure en prod' do
        let(:procedure) { create(:procedure, aasm_state: 'publiee', dossiers: dossiers) }
        let(:dossiers) do
          [
            create(:dossier, :en_construction),
            create(:dossier, :en_instruction),
            create(:dossier, :accepte)
          ]
        end

        it do
          is_expected.to include(
            ds_nb_demarches_actives: 1,
            ds_nb_demarches_archives: 0,
            ds_nb_demarches_brouillons: 0,
            nb_demarches_test: 0,
            nb_demarches_prod: 1,
            nb_demarches_prod_20: 0,
            nb_dossiers: 3,
            nb_dossiers_max: 3,
            nb_dossiers_traite: 1,
            nb_dossiers_dossier_en_instruction: 1
          )
        end
      end

      context 'with a procedure en prod and more than 20 dossiers' do
        let(:procedure) { create(:procedure, aasm_state: 'publiee', dossiers: dossiers) }
        let(:dossiers) do
          (1..7).flat_map do
            [
              create(:dossier, :en_construction),
              create(:dossier, :en_instruction),
              create(:dossier, :accepte)
            ]
          end
        end

        it do
          is_expected.to include(
            ds_nb_demarches_actives: 1,
            ds_nb_demarches_archives: 0,
            ds_nb_demarches_brouillons: 0,
            nb_demarches_test: 0,
            nb_demarches_prod: 1,
            nb_demarches_prod_20: 1,
            nb_dossiers: 21,
            nb_dossiers_max: 21,
            nb_dossiers_traite: 7,
            nb_dossiers_dossier_en_instruction: 7
          )
        end
      end
    end
  end
end
