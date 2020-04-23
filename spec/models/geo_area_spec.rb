RSpec.describe GeoArea, type: :model do
  describe '#area' do
    let(:geo_area) do
      create(:geo_area, geometry: {
        "type": "Polygon",
        "coordinates": [
          [
            [2.428439855575562, 46.538476837725796],
            [2.4284291267395024, 46.53842148758162],
            [2.4282521009445195, 46.53841410755813],
            [2.42824137210846, 46.53847314771794],
            [2.428284287452698, 46.53847314771794],
            [2.428364753723145, 46.538487907747864],
            [2.4284291267395024, 46.538491597754714],
            [2.428439855575562, 46.538476837725796]
          ]
        ]
      })
    end

    it { expect(geo_area.area).to eq(219.0) }
  end

  describe '#length' do
    let(:geo_area) do
      create(:geo_area, geometry: {
        "type": "LineString",
        "coordinates": [
          [2.4282521009445195, 46.53841410755813],
          [2.42824137210846, 46.53847314771794],
          [2.428284287452698, 46.53847314771794],
          [2.4284291267395024, 46.538491597754714]
        ]
      })
    end

    it { expect(geo_area.length).to eq(30.8) }
  end

  describe '#location' do
    let(:geo_area) do
      create(:geo_area, geometry: {
        "type": "Point",
        "coordinates": [2.428439855575562, 46.538476837725796]
      })
    end

    it { expect(geo_area.location).to eq("2°25'42\"N 46°32'19\"E") }
  end
end
