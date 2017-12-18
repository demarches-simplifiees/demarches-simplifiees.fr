require 'rails_helper'

RSpec.describe DossierHelper, type: :helper do
  describe ".highlight_if_unseen_class" do
    let(:seen_at) { DateTime.now }

    subject { highlight_if_unseen_class(seen_at, updated_at) }

    context "when commentaire date is created before last seen datetime" do
      let(:updated_at) { seen_at - 2.days }

      it { is_expected.to eq nil }
    end

    context "when commentaire date is created after last seen datetime" do
      let(:updated_at) { seen_at + 2.hours }

      it { is_expected.to eq "highlighted" }
    end

    context "when there is no last seen datetime" do
      let(:updated_at) { DateTime.now }
      let(:seen_at) { nil }

      it { is_expected.to eq nil }
    end
  end

  describe ".text_summary" do
    let(:procedure) { create(:procedure, libelle: "Procédure", organisation: "Organisme") }

    context 'when the dossier has been en_construction' do
      let(:dossier) { create :dossier, procedure: procedure, state: 'en_construction', en_construction_at: "31/12/2010".to_date }

      subject { text_summary(dossier) }

      it { is_expected.to eq("Dossier déposé le 31/12/2010 sur la procédure Procédure gérée par l'organisme Organisme") }
    end

    context 'when the dossier has not been en_construction' do
      let(:dossier) { create :dossier, procedure: procedure, state: 'brouillon' }

      subject { text_summary(dossier) }

      it { is_expected.to eq("Dossier en brouillon répondant à la procédure Procédure gérée par l'organisme Organisme") }
    end
  end
end