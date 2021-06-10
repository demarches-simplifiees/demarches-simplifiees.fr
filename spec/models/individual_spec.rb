describe Individual do
  it { is_expected.to have_db_column(:gender) }
  it { is_expected.to have_db_column(:nom) }
  it { is_expected.to have_db_column(:prenom) }
  it { is_expected.to belong_to(:dossier).required }

  describe "#save" do
    let(:individual) { build(:individual) }

    subject { individual.save }

    context "with birthdate" do
      before do
        individual.birthdate = birthdate_from_user
        subject
      end

      context "and the format is dd/mm/yyy " do
        let(:birthdate_from_user) { "12/11/1980" }

        it { expect(individual.birthdate).to eq(Date.new(1980, 11, 12)) }
      end

      context "and the format is ISO" do
        let(:birthdate_from_user) { "1980-11-12" }

        it { expect(individual.birthdate).to eq(Date.new(1980, 11, 12)) }
      end

      context "and the format is WTF" do
        let(:birthdate_from_user) { "1980 1 12" }

        it { expect(individual.birthdate).to be_nil }
      end
    end
  end

  describe "#api_particulier_donnees?" do
    subject { individual.api_particulier_donnees? }

    context "without data" do
      let(:individual) { Individual.new }

      it { expect(subject).to be false }
    end

    context "with empty data" do
      let(:individual) { Individual.new(api_particulier_donnees: { dgfip: {}, caf: {} }) }

      it { expect(subject).to be false }
    end

    context "with data" do
      let(:individual) { Individual.new(api_particulier_donnees: { dgfip: {}, caf: { quotient_familial: 1848 } }) }

      it { expect(subject).to be true }
    end
  end

  describe "validation" do
    let(:dossier) { build(:dossier, :with_individual) }
    let(:individual) { dossier.individual }
    let(:api_scopes) { nil }
    let(:api_sources) { nil }

    let(:numero_fiscal) { nil }
    let(:reference_avis) { nil }
    let(:numero_allocataire) { nil }
    let(:code_postal) { nil }
    let(:identifiant_pole_emploi) { nil }
    let(:ine) { nil }

    let(:attrs) do
      {
        api_particulier_dgfip_numero_fiscal: numero_fiscal,
        api_particulier_dgfip_reference_de_l_avis: reference_avis,
        api_particulier_caf_numero_d_allocataire: numero_allocataire,
        api_particulier_caf_code_postal: code_postal,
        api_particulier_pole_emploi_identifiant: identifiant_pole_emploi,
        api_particulier_mesri_ine: ine
      }
    end

    before do
      dossier.procedure.update(api_particulier_scopes: api_scopes, api_particulier_sources: api_sources)
    end

    subject { individual.update(attrs) }

    context "when API Particulier is enabled" do
      before do
        Flipper.enable(:api_particulier)
        subject
      end

      context "without scopes" do
        it { expect(individual).to be_valid }
      end

      context "with DGFIP scope" do
        let(:api_scopes) { APIParticulier::Types::DGFIP_SCOPES }
        let(:api_sources) { { dgfip: { avis_imposition: { situation_familiale: 1 } } } }

        context "and all mandatory fields whitespaced" do
          let(:numero_fiscal) { "2 008 399 999 000" }
          let(:reference_avis) { "20 08 399 999 000" }
          it { expect(individual).to be_valid }
        end

        context "and all mandatory fields" do
          let(:numero_fiscal) { "2008399999000" }
          let(:reference_avis) { "2008399999000" }
          it { expect(individual).to be_valid }
        end

        context "and missing 'référence' mandatory field" do
          let(:numero_fiscal) { "2008399999000" }
          it { expect(individual).not_to be_valid }
        end

        context "and missing 'numéro fiscal' mandatory field" do
          let(:reference_avis) { "2008399999000" }
          it { expect(individual).not_to be_valid }
        end

        context "and no mandatory field" do
          it { expect(individual).not_to be_valid }
        end
      end

      context "with CAF scope" do
        let(:api_scopes) { APIParticulier::Types::CAF_SCOPES }
        let(:api_sources) { { caf: { allocataires: { noms_et_prenoms: 1 } } } }

        context "and all mandatory fields whitespaced" do
          let(:numero_allocataire) { "0 000 354" }
          let(:code_postal) { "99 148" }
          it { expect(individual).to be_valid }
        end

        context "and all mandatory fields" do
          let(:numero_allocataire) { "0000354" }
          let(:code_postal) { "99148" }
          it { expect(individual).to be_valid }
        end

        context "and missing 'code postal' mandatory field" do
          let(:numero_allocataire) { "0000354" }
          it { expect(individual).not_to be_valid }
        end

        context "and missing 'numéro allocataire' mandatory field" do
          let(:code_postal) { "99148" }
          it { expect(individual).not_to be_valid }
        end

        context "and no mandatory field" do
          it { expect(individual).not_to be_valid }
        end
      end

      context "with Pole Emploi scope" do
        let(:api_scopes) { APIParticulier::Types::POLE_EMPLOI_SCOPES }
        let(:api_sources) { { pole_emploi: { situation: { email: 1 } } } }

        context "and all mandatory fields" do
          let(:identifiant_pole_emploi) { "adurand_28" }
          it { expect(individual).to be_valid }
        end

        context "and no mandatory field" do
          it { expect(individual).not_to be_valid }
        end
      end

      context "with MESRI scope" do
        let(:api_scopes) { APIParticulier::Types::ETUDIANT_SCOPES }
        let(:api_sources) { { mesri: { statut_etudiant: { date_de_naissance: 1 } } } }

        context "and all mandatory fields" do
          let(:ine) { "090 6018 155T" }
          it { expect(individual).to be_valid }
        end

        context "and no mandatory field" do
          it { expect(individual).not_to be_valid }
        end
      end
    end

    context "when API Particulier is disabled" do
      before do
        Flipper.disable(:api_particulier)
        subject
      end

      context "with scopes" do
        let(:api_scopes) { APIParticulier::Types::SCOPES }
        let(:api_sources) { { dgfip: { avis_imposition: { situation_familiale: 1 } } } }

        it { expect(individual).to be_valid }
      end

      context "without scopes" do
        it { expect(individual).to be_valid }
      end
    end
  end
end
