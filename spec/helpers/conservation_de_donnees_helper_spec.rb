require 'rails_helper'

RSpec.describe ConservationDeDonneesHelper, type: :helper do
  let(:procedure) { build(:procedure, duree_conservation_dossiers_dans_ds: dans_ds, duree_conservation_dossiers_hors_ds: hors_ds) }

  describe "politiques_conservation_de_donnees" do
    subject { politiques_conservation_de_donnees(procedure) }

    context "when both retention times are set" do
      let(:dans_ds) { 3 }
      let(:hors_ds) { 6 }

      it { is_expected.to eq([ "Dans #{SITE_NAME} : 3 mois", "Par l’administration : 6 mois" ]) }
    end

    context "when only in-app retention time is set" do
      let(:dans_ds) { 3 }
      let(:hors_ds) { nil }

      it { is_expected.to eq([ "Dans #{SITE_NAME} : 3 mois" ]) }
    end

    context "when only out of app retention time is set" do
      let(:dans_ds) { nil }
      let(:hors_ds) { 6 }

      it { is_expected.to eq([ "Par l’administration : 6 mois" ]) }
    end

    context "when the retention time is not set" do
      let(:dans_ds) { nil }
      let(:hors_ds) { nil }

      it { is_expected.to be_empty }
    end
  end
end
