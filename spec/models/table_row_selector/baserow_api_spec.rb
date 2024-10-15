require 'rails_helper'
require 'webmock/rspec'
require 'vcr'

RSpec.describe TableRowSelector::BaserowAPI, type: :model do
  describe '#search' do
    it 'search in a Baserow table and return the result', :vcr do
      allow(TableRowSelector::BaserowAPI).to receive(:config).and_return({
        'Table' => '202600',
        'Champ de recherche' => 'search_field',
        'Token' => ENV['API_BASEROW_TOKEN'].to_s
      })

      VCR.use_cassette('baserow_search') do
        results = TableRowSelector::BaserowAPI.search(123, "term")

        expect(results).to be_an(Array)
        expect(results.length).to be > 0
        expect(results.first).to have_key(:name)
        expect(results.first).to have_key(:id)
      end
    end
  end

  describe '#fetch_row' do
    it 'fetch a specific line in a Baserow table', :vcr do
      allow(TableRowSelector::BaserowAPI).to receive(:config).and_return({
        'Table' => '202600',
        'Token' => ENV['API_BASEROW_TOKEN'].to_s
      })

      VCR.use_cassette('baserow_fetch_row') do
        result = TableRowSelector::BaserowAPI.fetch_row(123, 1)

        expect(result[:row]["Nom"]).to eq("Communes de polynésie")
        expect(result[:row]["Notes"]).to eq("")
        expect(result[:row]["Actif"]).to eq(true)
        expect(result[:row]["Table"]).to eq("202578")
        expect(result[:row]["Champs usager"]).to eq("1391747,1391750,1391755,1391756")
        expect(result[:row]["Champ de recherche"]).to eq("1391747")
        expect(result[:row]["Champs instructeur"]).to eq("1391747,1391750,1391755,1391756")
      end
    end
  end

  describe '#available_tables' do
    it 'fetch the available tables', :vcr do
      allow(TableRowSelector::BaserowAPI).to receive(:config)

      VCR.use_cassette('baserow_available_tables') do
        results = TableRowSelector::BaserowAPI.available_tables

        expect(results).to be_an(Array)
        expect(results.first[:name]).to eq("Communes de polynésie")
        expect(results.first[:id]).to eq(1)
      end
    end
  end
end
