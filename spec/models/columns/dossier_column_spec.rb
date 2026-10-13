# frozen_string_literal: true

describe Columns::DossierColumn do
  describe 'value' do
    let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [create(:instructeur)]) }

    context 'when dossier columns' do
      context 'when procedure for individual' do
        let(:individual) { create(:individual, nom: "Sim", prenom: "Paul", gender: 'M.') }
        let(:procedure) { create(:procedure, for_individual: true, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, individual:, mandataire_first_name: "Martin", mandataire_last_name: "Christophe", for_tiers: true) }

        it 'retrieve individual information' do
          expect(procedure.find_column(label: "Prénom [Identité du demandeur]").value(dossier)).to eq("Paul")
          expect(procedure.find_column(label: "Nom [Identité du demandeur]").value(dossier)).to eq("Sim")
          expect(procedure.find_column(label: "Dépôt pour un tiers").value(dossier)).to eq(true)
          expect(procedure.find_column(label: "Nom [Identité du mandataire]").value(dossier)).to eq("Christophe")
          expect(procedure.find_column(label: "Prénom [Identité du mandataire]").value(dossier)).to eq("Martin")
        end
      end

      context 'when procedure for entreprise' do
        let(:procedure) { create(:procedure, for_individual: false, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure:) }

        it 'retrieve entreprise information' do
          expect(procedure.find_column(label: "N° dossier").value(dossier)).to eq(dossier.id)
          expect(procedure.find_column(label: "Adresse électronique").value(dossier)).to eq(dossier.user_email_for(:display))
          expect(procedure.find_column(label: "France connecté ?").value(dossier)).to eq(false)
          expect(procedure.find_column(label: "Entreprise forme juridique").value(dossier)).to eq("SA à conseil d’administration (s.a.i.)")
          expect(procedure.find_column(label: "Entreprise SIREN").value(dossier)).to eq('440117620')
          expect(procedure.find_column(label: "Entreprise nom commercial").value(dossier)).to eq('GRTGAZ')
          expect(procedure.find_column(label: "Entreprise raison sociale").value(dossier)).to eq('GRTGAZ')
          expect(procedure.find_column(label: "Entreprise SIRET siège social").value(dossier)).to eq('44011762001530')
          expect(procedure.find_column(label: "Date de création").value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "Établissement SIRET").value(dossier)).to eq('44011762001530')
          expect(procedure.find_column(label: "Libellé NAF").value(dossier)).to eq('Transports par conduites')
          expect(procedure.find_column(label: "Code NAF").value(dossier)).to eq('4950Z')
          expect(procedure.find_column(label: "Établissement code postal").value(dossier)).to eq('92270')
          expect(procedure.find_column(label: "Établissement siège social").value(dossier)).to eq(true)
          expect(procedure.find_column(label: "Établissement Adresse").value(dossier)).to eq("GRTGAZ\r IMMEUBLE BORA\r 6 RUE RAOUL NORDLING\r 92270 BOIS COLOMBES\r")
          expect(procedure.find_column(label: "Établissement numero voie").value(dossier)).to eq('6')
          expect(procedure.find_column(label: "Établissement type voie").value(dossier)).to eq('RUE')
          expect(procedure.find_column(label: "Établissement nom voie").value(dossier)).to eq('RAOUL NORDLING')
          expect(procedure.find_column(label: "Établissement complément adresse").value(dossier)).to eq('IMMEUBLE BORA')
          expect(procedure.find_column(label: "Établissement localité").value(dossier)).to eq('BOIS COLOMBES')
          expect(procedure.find_column(label: "Établissement code INSEE localité").value(dossier)).to eq('92009')
          expect(procedure.find_column(label: "Entreprise SIREN").value(dossier)).to eq('440117620')
          expect(procedure.find_column(label: "Entreprise capital social").value(dossier)).to eq(537_100_000)
          expect(procedure.find_column(label: "Entreprise numero TVA intracommunautaire").value(dossier)).to eq('FR27440117620')
          expect(procedure.find_column(label: "Entreprise forme juridique code").value(dossier)).to eq('5599')
          expect(procedure.find_column(label: "Entreprise code effectif entreprise").value(dossier)).to eq('51')
          expect(procedure.find_column(label: "Entreprise état administratif").value(dossier)).to eq("actif")
          expect(procedure.find_column(label: "Entreprise nom").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Entreprise prénom").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association RNA").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association titre").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association objet").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association date de création").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association date de déclaration").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Association date de publication").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Date de création").value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "Date du dernier évènement").value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "Date de dépôt").value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "Date de passage en construction").value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "Date de passage en instruction").value(dossier)).to be_an_instance_of(ActiveSupport::TimeWithZone)
          expect(procedure.find_column(label: "Date de traitement").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "État du dossier").value(dossier)).to eq('en_instruction')
          expect(procedure.find_column(label: "Archivé").value(dossier)).to eq(false)
          expect(procedure.find_column(label: "Motivation de la décision").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Date de dernière modification (usager)").value(dossier)).to eq(nil)
          expect(procedure.find_column(label: "Instructeurs").value(dossier)).to eq('')
        end
      end

      context 'when procedure for entreprise which is also an association' do
        let(:procedure) { create(:procedure, for_individual: false, groupe_instructeurs: [groupe_instructeur]) }
        let(:etablissement) { create(:etablissement, :is_association) }
        let(:dossier) { create(:dossier, :en_instruction, procedure:, etablissement:) }

        it 'retrieve also association information' do
          expect(procedure.find_column(label: "Association RNA").value(dossier)).to eq("W072000535")
          expect(procedure.find_column(label: "Association titre").value(dossier)).to eq("ASSOCIATION POUR LA PROMOTION DE SPECTACLES AU CHATEAU DE ROCHEMAURE")
          expect(procedure.find_column(label: "Association objet").value(dossier)).to eq("mise en oeuvre et réalisation de spectacles au chateau de rochemaure")
          expect(procedure.find_column(label: "Association date de création").value(dossier)).to eq(Date.parse("1990-04-24"))
          expect(procedure.find_column(label: "Association date de déclaration").value(dossier)).to eq(Date.parse("2014-11-28"))
          expect(procedure.find_column(label: "Association date de publication").value(dossier)).to eq(Date.parse("1990-05-16"))
        end
      end

      context 'when the dossier has no etablissement yet, only an unverified SIRET' do
        let(:procedure) { procedures.entreprise }
        let(:dossier) { dossiers.entreprise_en_instruction }

        before do
          dossier.etablissement.destroy!
          dossier.reload.create_demandeur_siret!(siret: '30613890001294', external_state: 'degraded')
          dossier.reload
        end

        it 'reads nothing from the etablissement, without failing' do
          expect(procedure.find_column(label: "Entreprise raison sociale").value(dossier)).to be_nil
        end
      end

      context 'when sva/svr enabled' do
        let(:procedure) { create(:procedure, :sva, for_individual: true, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, :en_instruction, procedure:) }

        it 'does not fail' do
          expect(procedure.find_column(label: "Date décision SVA").value(dossier)).to eq(nil)
        end
      end
    end
  end

  describe '#filtered_ids' do
    context 'for a boolean etablissement column (siege_social)' do
      let(:procedure) { create(:procedure, for_individual: false) }
      let(:column) { procedure.find_column(label: 'Établissement siège social') }
      let!(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure:) }

      before { dossier.etablissement.update!(siege_social: true) }

      def filtering(value) = column.filtered_ids(procedure.dossiers, { operator: 'match', value: })

      it 'filters on the boolean' do
        expect(filtering(['true'])).to eq([dossier.id])
        expect(filtering(['false'])).to eq([])
      end

      it 'offers the oui/non options the radio buttons are built from' do
        expect(column.options_for_select).to eq(Champs::YesNoChamp.options)
      end
    end

    context 'for an integer etablissement column' do
      let(:procedure) { create(:procedure, for_individual: false) }
      let!(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure:) }
      let(:capital) { dossier.etablissement.entreprise_capital_social }
      let(:integer_column) { procedure.find_column(label: "Entreprise capital social") }

      subject { integer_column.filtered_ids(procedure.dossiers, { operator: 'match', value: [capital.to_s] }) }

      it { is_expected.to eq([dossier.id]) }
    end

    context 'for a dossier state column' do
      let(:procedure) { create(:procedure, for_individual: false) }
      let!(:dossier_en_instruction) { create(:dossier, :en_instruction, procedure:) }
      let!(:dossier_en_construction) { create(:dossier, :en_construction, procedure:) }
      let!(:dossier_accepte) { create(:dossier, :accepte, procedure:) }

      let(:state_column) { procedure.find_column(label: "État du dossier") }

      subject { state_column.filtered_ids(procedure.dossiers, search_terms) }

      context 'when searching for en_construction' do
        let(:search_terms) { { operator: 'match', value: ["en_construction"] } }

        it { is_expected.to contain_exactly(dossier_en_construction.id) }
      end

      context 'when searching for accepte' do
        let(:search_terms) { { operator: 'match', value: ["accepte"] } }
        it { is_expected.to contain_exactly(dossier_accepte.id) }
      end

      context 'when searching for en_instruction' do
        let(:search_terms) { { operator: 'match', value: ["en_instruction"] } }
        it { is_expected.to contain_exactly(dossier_en_instruction.id) }
      end

      context 'when searching for multiple states' do
        let(:search_terms) { { operator: 'match', value: ["en_construction", "accepte"] } }

        it { is_expected.to contain_exactly(dossier_en_construction.id, dossier_accepte.id) }
      end
    end

    context 'for a datetime column' do
      let(:procedure) { create(:procedure, for_individual: false) }
      let(:date_column) { procedure.find_column(label: "Date de création") }

      subject { date_column.filtered_ids(procedure.dossiers, search_terms) }

      context 'when searching with before operator' do
        let!(:dossier) { travel_to(DateTime.parse("12/02/2025 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier2) { travel_to(DateTime.parse("15/02/2025 09:19")) { create(:dossier, :en_instruction, procedure:) } }

        let(:search_terms) { { operator: 'before', value: ["2025-02-13"] } }

        it { is_expected.to contain_exactly(dossier.id) }
      end

      context 'when searching with after operator' do
        let!(:dossier) { travel_to(DateTime.parse("12/02/2025 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier2) { travel_to(DateTime.parse("15/02/2025 09:19")) { create(:dossier, :en_instruction, procedure:) } }

        let(:search_terms) { { operator: 'after', value: ["2025-02-13"] } }

        it { is_expected.to contain_exactly(dossier2.id) }

        context "for updated_since column (special case)" do
          let(:date_column) { procedure.find_column(label: "Dernier évènement depuis") }
          it { is_expected.to contain_exactly(dossier2.id) }
        end
      end

      context 'when searching with between operator' do
        let!(:dossier_before) { travel_to(Time.zone.parse("11/02/2025 12:00")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_first_day) { travel_to(Time.zone.parse("12/02/2025 12:00")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_last_day) { travel_to(Time.zone.parse("15/02/2025 12:00")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_after) { travel_to(Time.zone.parse("16/02/2025 12:00")) { create(:dossier, :en_instruction, procedure:) } }

        context 'with both bounds' do
          let(:search_terms) { { operator: 'between', value: ["2025-02-12", "2025-02-15"] } }

          it { is_expected.to contain_exactly(dossier_first_day.id, dossier_last_day.id) }
        end

        context 'with the same day as both bounds' do
          let(:search_terms) { { operator: 'between', value: ["2025-02-12", "2025-02-12"] } }

          it { is_expected.to contain_exactly(dossier_first_day.id) }
        end

        context 'with only a start date' do
          let(:search_terms) { { operator: 'between', value: ["2025-02-12", ""] } }

          it { is_expected.to contain_exactly(dossier_first_day.id, dossier_last_day.id, dossier_after.id) }
        end

        context 'with only an end date' do
          let(:search_terms) { { operator: 'between', value: ["", "2025-02-15"] } }

          it { is_expected.to contain_exactly(dossier_before.id, dossier_first_day.id, dossier_last_day.id) }
        end

        context 'with unparseable dates' do
          let(:search_terms) { { operator: 'between', value: ["abc", "2024-13-45"] } }

          it { is_expected.to contain_exactly(dossier_before.id, dossier_first_day.id, dossier_last_day.id, dossier_after.id) }
        end
      end

      # update_filter neither whitelists the operator nor validates the date, so
      # both of these reach the column.
      context 'when searching with a date the filter form let through' do
        let!(:dossier) { travel_to(DateTime.parse("12/02/2025 09:19")) { create(:dossier, :en_instruction, procedure:) } }

        context 'out of range' do
          let(:search_terms) { { operator: 'before', value: ['2024-13-45'] } }

          it { is_expected.to contain_exactly(dossier.id) }
        end

        context 'unparseable' do
          let(:search_terms) { { operator: 'after', value: ['abc'] } }

          it { is_expected.to contain_exactly(dossier.id) }
        end
      end

      context 'when searching with this_week operator' do
        let(:search_terms) { { operator: 'this_week' } }

        let!(:dossier_at_the_beginning_of_the_week) { travel_to(DateTime.parse("2025-02-03 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_at_the_end_of_the_week) { travel_to(DateTime.parse("2025-02-09 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_week_before) { travel_to(DateTime.parse("2025-02-02 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_week_after) { travel_to(DateTime.parse("2025-02-10 09:19")) { create(:dossier, :en_instruction, procedure:) } }

        before do
          travel_to(Time.zone.parse("2025-02-08"))
        end

        it "returns dossiers from this week" do
          expect(subject).to match_array([dossier_at_the_beginning_of_the_week.id, dossier_at_the_end_of_the_week.id])
        end
      end

      context 'when searching with this_month operator' do
        let(:search_terms) { { operator: 'this_month' } }

        let!(:dossier_at_the_beginning_of_the_month) { travel_to(DateTime.parse("2025-02-01 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_at_the_end_of_the_month) { travel_to(DateTime.parse("2025-02-28 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_month_before) { travel_to(DateTime.parse("2025-01-13 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_month_after) { travel_to(DateTime.parse("2025-03-13 09:19")) { create(:dossier, :en_instruction, procedure:) } }

        before do
          travel_to(Time.zone.parse("2025-02-13"))
        end

        it "returns dossiers from this month" do
          expect(subject).to match_array([dossier_at_the_beginning_of_the_month.id, dossier_at_the_end_of_the_month.id])
        end
      end

      context 'when searching with this_year operator' do
        let(:search_terms) { { operator: 'this_year' } }

        let!(:dossier_at_the_beginning_of_the_year) { travel_to(DateTime.parse("2024-01-01 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_at_the_end_of_the_year) { travel_to(DateTime.parse("2024-12-31 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_year_before) { travel_to(DateTime.parse("2023-12-31 09:19")) { create(:dossier, :en_instruction, procedure:) } }
        let!(:dossier_year_after) { travel_to(DateTime.parse("2025-01-01 09:19")) { create(:dossier, :en_instruction, procedure:) } }

        before do
          travel_to(Time.zone.parse("2024-02-13"))
        end

        it "returns dossiers from this year" do
          expect(subject).to match_array([dossier_at_the_beginning_of_the_year.id, dossier_at_the_end_of_the_year.id])
        end
      end
    end
  end

  describe '#sorted_ids' do
    let(:procedure) { create(:procedure, :published) }
    let(:order) { 'asc' } # Desc works the same, no extra test required

    subject { column.sorted_ids(procedure.dossiers, order) }

    context 'for self table' do
      context 'for created_at column' do
        let!(:column) { procedure.find_column(label: 'Date de création') }
        let!(:recent_dossier) { travel_to(Time.zone.local(2018, 10, 17)) { create(:dossier, procedure:) } }
        let!(:older_dossier) { travel_to(Time.zone.local(2003, 11, 11)) { create(:dossier, procedure:) } }

        it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
      end

      context 'for en_construction_at column' do
        let!(:column) { procedure.find_column(label: 'Date de passage en construction') }
        let!(:recent_dossier) { create(:dossier, :en_construction, procedure:, en_construction_at: Time.zone.local(2018, 10, 17)) }
        let!(:older_dossier) { create(:dossier, :en_construction, procedure:, en_construction_at: Time.zone.local(2013, 1, 1)) }

        it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
      end

      context 'for updated_at column' do
        let(:column) { procedure.find_column(label: 'Date du dernier évènement') }
        let(:recent_dossier) { create(:dossier, procedure:) }
        let(:older_dossier) { create(:dossier, procedure:) }

        before do
          recent_dossier.touch(time: Time.zone.local(2018, 9, 25))
          older_dossier.touch(time: Time.zone.local(2018, 5, 13))
        end

        it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
      end
    end

    context 'for individual table' do
      let(:procedure) { create(:procedure, :for_individual) }

      let!(:first_dossier) { create(:dossier, procedure:, individual: build(:individual, gender: 'M', prenom: 'Alain', nom: 'Antonelli')) }
      let!(:last_dossier) { create(:dossier, procedure:, individual: build(:individual, gender: 'Mme', prenom: 'Zora', nom: 'Zemmour')) }

      context 'for gender column' do
        before do
          procedure.update!(no_gender: false)
        end

        let(:column) { procedure.find_column(label: 'Civilité') }

        it { is_expected.to eq([first_dossier, last_dossier].map(&:id)) }
      end

      context 'for prenom column' do
        let(:column) { procedure.find_column(label: 'Prénom [Identité du demandeur]') }

        it { is_expected.to eq([first_dossier, last_dossier].map(&:id)) }
      end

      context 'for nom column' do
        let(:column) { procedure.find_column(label: 'Nom [Identité du demandeur]') }

        it { is_expected.to eq([first_dossier, last_dossier].map(&:id)) }
      end
    end

    context 'for other tables' do
      # All other columns and tables work the same so it’s ok to test only one
      let(:column) { procedure.find_column(label: 'Établissement code postal') }

      let!(:huitieme_dossier) { create(:dossier, procedure:, etablissement: create(:etablissement, code_postal: '75008')) }
      let!(:vingtieme_dossier) { create(:dossier, procedure:, etablissement: create(:etablissement, code_postal: '75020')) }

      it { is_expected.to eq([huitieme_dossier, vingtieme_dossier].map(&:id)) }
    end

    context 'for etablissement code_naf column (aliased to naf)' do
      let(:column) { procedure.find_column(label: 'Code NAF') }

      let!(:first_dossier) { create(:dossier, procedure:, etablissement: create(:etablissement, naf: '1234Z')) }
      let!(:second_dossier) { create(:dossier, procedure:, etablissement: create(:etablissement, naf: '9999Z')) }

      it { is_expected.to eq([first_dossier.id, second_dossier.id]) }
    end
  end
end
