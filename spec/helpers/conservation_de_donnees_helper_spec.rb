RSpec.describe ConservationDeDonneesHelper, type: :helper do
  let(:procedure) { build(:procedure, duree_conservation_dossiers_dans_ds: dans_ds) }

  describe "politiques_conservation_de_donnees" do
    subject { politiques_conservation_de_donnees(procedure) }

    context "when retention time is set" do
      let(:dans_ds) { 3 }
      let(:hors_ds) { 6 }

      it { is_expected.to eq(["#{APPLICATION_NAME} : 3 mois"]) }
    end

    context "when the retention time is not set" do
      let(:dans_ds) { nil }
      let(:hors_ds) { nil }

      it { is_expected.to be_empty }
    end
  end
end
