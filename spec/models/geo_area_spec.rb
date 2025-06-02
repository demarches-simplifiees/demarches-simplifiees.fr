# frozen_string_literal: true

RSpec.describe GeoArea, type: :model do
  describe '#area' do
    let(:geo_area) { build(:geo_area, :polygon, champ: nil) }

    it { expect(geo_area.area).to eq(103.6) }
  end

  describe '#area (hourglass polygon)' do
    let(:geo_area) { build(:geo_area, :hourglass_polygon, champ: nil) }

    it { expect(geo_area.area).to eq(32.4) }
  end

  describe '#length' do
    let(:geo_area) { build(:geo_area, :line_string, champ: nil) }

    it { expect(geo_area.length).to eq(21.2) }
  end

  describe '#location' do
    let(:geo_area) { build(:geo_area, :point, champ: nil) }

    it { expect(geo_area.location).to eq("46°32'19\"N 2°25'42\"E") }
  end

  describe 'validations' do
    context 'geometry' do
      subject! { geo_area.validate }

      context 'polygon' do
        let(:geo_area) { build(:geo_area, :polygon, champ: nil) }
        it { expect(geo_area.errors).not_to have_key(:geometry) }
      end

      context 'line_string' do
        let(:geo_area) { build(:geo_area, :line_string, champ: nil) }
        it { expect(geo_area.errors).not_to have_key(:geometry) }
      end

      context 'point' do
        let(:geo_area) { build(:geo_area, :point, champ: nil) }
        it { expect(geo_area.errors).not_to have_key(:geometry) }
      end

      context "allow empty {}" do
        let(:geo_area) { build(:geo_area, geometry: {}) }
        it { expect(geo_area.errors).not_to have_key(:geometry) }
      end

      context "nil" do
        let(:geo_area) { build(:geo_area, geometry: nil) }
        it { expect(geo_area.errors).to have_key(:geometry) }
      end

      context 'invalid point' do
        let(:geo_area) { build(:geo_area, :invalid_point, champ: nil) }
        it { expect(geo_area.errors).to have_key(:geometry) }
      end

      context 'invalid_right_hand_rule_polygon' do
        let(:geo_area) { build(:geo_area, :invalid_right_hand_rule_polygon, champ: nil) }
        it { expect(geo_area.errors).to have_key(:geometry) }
      end

      context 'hourglass_polygon' do
        let(:geo_area) { build(:geo_area, :hourglass_polygon, champ: nil) }
        it { expect(geo_area.errors).to have_key(:geometry) }
      end
    end
  end

  describe "cadastre properties" do
    let(:geo_area) { build(:geo_area, :cadastre, champ: nil) }
    let(:legacy_geo_area) { build(:geo_area, :legacy_cadastre, champ: nil) }

    it "should be backward compatible" do
      expect("#{geo_area.code_dep}#{geo_area.code_com}").to eq(geo_area.commune)
      expect(geo_area.code_arr).to eq(geo_area.prefixe)
      expect(geo_area.surface_parcelle).to eq(geo_area.surface)
    end

    context "(legacy)" do
      it "should be forward compatible" do
        expect("#{legacy_geo_area.code_dep}#{legacy_geo_area.code_com}").to eq(legacy_geo_area.commune)
        expect(legacy_geo_area.code_arr).to eq(legacy_geo_area.prefixe)
        expect(legacy_geo_area.surface_parcelle).to eq(legacy_geo_area.surface)
        expect(legacy_geo_area.cid).to eq(geo_area.cid)
      end
    end
  end

  describe 'description' do
    context 'when properties is nil' do
      let(:geo_area) { build(:geo_area, properties: nil, champ: nil) }

      it { expect(geo_area.description).to be_nil }
    end
  end

  describe "#label" do
    context "when geo is a line" do
      let(:geo_area) { build(:geo_area, :selection_utilisateur, :line_string, champ: nil) }
      it "should return the label" do
        expect(geo_area.label).to eq("Une ligne longue de 21,2 m")
      end

      it "should return unknown length" do
        geo_area.geometry["coordinates"] = []
        expect(geo_area.label).to eq("Une ligne de longueur inconnue")
      end
    end

    context "when geo is a polygon" do
      let(:geo_area) { build(:geo_area, :selection_utilisateur, :polygon, champ: nil) }
      it "should return the label" do
        expect(geo_area.label).to eq("Une aire de surface 103,6 m²")
      end

      it "should return unknown surface" do
        geo_area.geometry["coordinates"] = []
        expect(geo_area.label).to eq("Une aire de surface inconnue")
      end
    end

    context "when geo is a point" do
      let(:geo_area) { build(:geo_area, :selection_utilisateur, :point, champ: nil) }
      it "should return the label" do
        expect(geo_area.label).to eq("Un point situé à 46°32'19\"N 2°25'42\"E")
      end
    end

    context "when geo is a point with elevation" do
      let(:geo_area) { build(:geo_area, :selection_utilisateur, :point_with_z, champ: nil) }
      it "should return the label" do
        expect(geo_area.label).to eq("Un point situé à 46°32'19\"N 2°25'42\"E")
      end
    end

    context "when geo is a cadastre parcelle" do
      let(:geo_area) { build(:geo_area, :selection_utilisateur, :cadastre, champ: nil) }
      it "should return the label" do
        expect(geo_area.label).to eq("Parcelle n° 42 - Feuille 000 A11 - 123 m² – commune 75127")
      end
    end
  end
end
