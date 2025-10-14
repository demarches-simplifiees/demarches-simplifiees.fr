# frozen_string_literal: true

describe APIGeoDegradedService do
  let(:departements_data) do
    APIGeoService.departements.each_with_object({}) do |departement, data|
      next if departement[:code] == '99'
      data[departement[:code]] = APIGeoService.send(:get_from_api_geo, "communes-#{departement[:code]}")
    end
  end

  describe '.fetch_communes_by_name' do
    it 'boost exact match and sort by postal code' do
      response = APIGeoDegradedService.fetch_communes_by_name('Paris', departements_data)

      expect(response.success?).to be true
      expect(response.code).to eq(200)

      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      expect(body.first['nom']).to eq('Paris')
      expect(body.first['code']).to eq('75056')
      expect(body.first['codesPostaux']).to eq(['75001'])
    end

    it 'handle spaces and dash in query' do
      response = APIGeoDegradedService.fetch_communes_by_name('bouc bel a', departements_data)

      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      expect(body.first['nom']).to eq('Bouc-Bel-Air')
    end
  end

  describe '.fetch_communes_by_postal_code' do
    it 'find a commune by postal code' do
      response = APIGeoDegradedService.fetch_communes_by_postal_code('07470', departements_data)

      expect(response.success?).to be true
      body = JSON.parse(response.body)

      expect(body).to be_an(Array)
      expect(body.first['nom']).to eq('Coucouron')
      expect(body.first['codesPostaux']).to include('07470')
    end
  end

  describe 'Response data structure' do
    it 'returns same response as API geo' do
      response = APIGeoDegradedService.fetch_communes_by_name('Paris', departements_data)
      body = JSON.parse(response.body)
      commune = body.first

      expect(commune['nom']).to eq("Paris")
      expect(commune['code']).to eq("75056")
      expect(commune['codesPostaux']).to eq(["75001"])
      expect(commune['codeDepartement']).to eq("75")
      expect(commune['codeRegion']).to eq("11")
      expect(commune).to have_key('population')
    end
  end
end
