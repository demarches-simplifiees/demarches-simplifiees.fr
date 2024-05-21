describe Etablissement do
  describe '#geo_adresse' do
    let(:etablissement) { create(:etablissement) }

    subject { etablissement.geo_adresse }

    it { is_expected.to eq '6 RUE RAOUL NORDLING IMMEUBLE BORA 92270 BOIS COLOMBES' }
  end

  describe '#inline_adresse' do
    let(:etablissement) { create(:etablissement, nom_voie: 'green    moon') }

    it { expect(etablissement.inline_adresse).to eq '6 RUE green moon, IMMEUBLE BORA, 92270 BOIS COLOMBES' }

    context 'with missing complement adresse' do
      let(:expected_adresse) { '6 RUE RAOUL NORDLING, 92270 BOIS COLOMBES' }
      subject { etablissement.inline_adresse }

      context 'when blank' do
        let(:etablissement) { create(:etablissement, complement_adresse: '') }

        it { is_expected.to eq expected_adresse }
      end

      context 'when whitespace' do
        let(:etablissement) { create(:etablissement, complement_adresse: '   ') }

        it { is_expected.to eq expected_adresse }
      end

      context 'when nil' do
        let(:etablissement) { create(:etablissement, complement_adresse: nil) }

        it { is_expected.to eq expected_adresse }
      end
    end
  end

  describe '#entreprise_raison_sociale' do
    subject { etablissement.entreprise_raison_sociale }

    context "with nom and prenom" do
      context "without raison sociale" do
        let(:etablissement) { create(:etablissement, entreprise_raison_sociale: nil, entreprise_prenom: "Stef", entreprise_nom: "Sanseverino") }

        it { is_expected.to eq "Sanseverino Stef" }
      end

      context "with raison sociale" do
        let(:etablissement) { create(:etablissement, entreprise_raison_sociale: "Sansev Prod", entreprise_prenom: "Stef", entreprise_nom: "Sanseverino") }

        it { is_expected.to eq "Sansev Prod" }
      end
    end

    context "without nom and prenom" do
      let(:etablissement) { create(:etablissement, entreprise_raison_sociale: "ENGIE", entreprise_prenom: nil, entreprise_nom: nil) }

      it { is_expected.to eq "ENGIE" }
    end
  end

  describe '.entreprise_bilans_bdf_to_csv' do
    let(:etablissement) { build(:etablissement, entreprise_bilans_bdf: bilans) }
    let(:ordered_headers) {
      [
        "date_arret_exercice", "duree_exercice", "chiffre_affaires_ht", "evolution_chiffre_affaires_ht",
        "valeur_ajoutee_bdf", "evolution_valeur_ajoutee_bdf", "excedent_brut_exploitation",
        "evolution_excedent_brut_exploitation", "resultat_exercice", "evolution_resultat_exercice",
        "capacite_autofinancement", "evolution_capacite_autofinancement", "fonds_roulement_net_global",
        "evolution_fonds_roulement_net_global", "besoin_en_fonds_de_roulement", "evolution_besoin_en_fonds_de_roulement",
        "ratio_fonds_roulement_net_global_sur_besoin_en_fonds_de_roulement",
        "evolution_ratio_fonds_roulement_net_global_sur_besoin_en_fonds_de_roulement", "disponibilites",
        "evolution_disponibilites", "capital_social_inclus_dans_capitaux_propres_et_assimiles",
        "evolution_capital_social_inclus_dans_capitaux_propres_et_assimiles", "capitaux_propres_et_assimiles",
        "evolution_capitaux_propres_et_assimiles", "autres_fonds_propres", "evolution_autres_fonds_propres",
        "total_provisions_pour_risques_et_charges", "evolution_total_provisions_pour_risques_et_charges",
        "dettes1_emprunts_obligataires_et_convertibles", "evolution_dettes1_emprunts_obligataires_et_convertibles",
        "dettes2_autres_emprunts_obligataires", "evolution_dettes2_autres_emprunts_obligataires",
        "dettes3_emprunts_et_dettes_aupres_des_etablissements_de_credit",
        "evolution_dettes3_emprunts_et_dettes_aupres_des_etablissements_de_credit",
        "dettes4_maturite_a_un_an_au_plus", "evolution_dettes4_maturite_a_un_an_au_plus",
        "emprunts_et_dettes_financieres_divers", "evolution_emprunts_et_dettes_financieres_divers",
        "total_dettes_stables", "evolution_total_dettes_stables", "groupes_et_associes",
        "evolution_groupes_et_associes", "total_passif", "evolution_total_passif"
      ]
    }
    let(:bilans) do
      [
        {
          "total_passif": "1200",
          "chiffre_affaires_ht": "40000"
        },
        {
          "total_passif": "0",
          "new_key": "50",
          "evolution_total_dettes_stables": "30"
        }
      ]
    end

    subject { etablissement.entreprise_bilans_bdf_to_sheet('csv').split("\n") }

    it "build a csv with keys in right order" do
      headers = subject[0].split(',')
      expect(headers).to eq(ordered_headers.concat(["new_key"]))
    end

    it "build a csv with good values" do
      bilans_h = csv_to_array_of_hash(subject)
      expect(bilans_h[0]["total_passif"]).to eq("1200")
      expect(bilans_h[0]["chiffre_affaires_ht"]).to eq("40000")
      expect(bilans_h[1]["evolution_total_dettes_stables"]).to eq("30")
      expect(bilans_h[1]["new_key"]).to eq("50")
    end
  end

  describe 'update search terms' do
    let(:etablissement) { create(:etablissement, dossier: build(:dossier)) }

    it "schedule update search terms" do
      assert_enqueued_jobs(1, only: DossierIndexSearchTermsJob) do
        etablissement.update(entreprise_nom: "nom")
      end
    end
  end

  private

  def csv_to_array_of_hash(lines)
    headers = lines.shift.split(',')
    lines.map { |line| line_to_hash(line, headers) }
  end

  def line_to_hash(line, headers)
    bilan = {}
    line.split(',').each_with_index do |value, index|
      bilan[headers[index]] = value
    end
    bilan
  end
end
