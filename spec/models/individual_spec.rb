require 'spec_helper'

describe Individual do
  it { is_expected.to have_db_column(:gender) }
  it { is_expected.to have_db_column(:nom) }
  it { is_expected.to have_db_column(:prenom) }
  it { is_expected.to belong_to(:dossier) }

  describe "#save" do
    let(:individual) { build(:individual, prenom: 'adÉlaÏde') }

    context "normalization of nom and prenom" do
      before do
        individual.save
      end

      it { expect(individual.nom).to eq('JULIEN') }
      it { expect(individual.prenom).to eq('Adélaïde') }
    end

    context "with birthdate" do
      before do
        individual.birthdate = birthdate_from_user
        individual.save
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
end
