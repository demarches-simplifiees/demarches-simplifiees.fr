require 'spec_helper'

describe Typhoeus::Cache::SuccessfulRequestsRailsCache, lib: true do
  let(:cache) { described_class.new }

  let(:base_url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(base_url, { :method => :get, cache: cache, cache_ttl: 1.day }) }
  let(:response) { Typhoeus::Response.new(:response_code => response_code, :return_code => 0, :mock => true) }
  let(:response_code) { 0 }

  before { Rails.cache.clear }

  describe "#set" do
    context 'when the request is successful' do
      let(:response_code) { 200 }

      it 'saves the request in the Rails cache' do
        cache.set(request, response)
        expect(Rails.cache.exist?(request)).to be true
        expect(Rails.cache.read(request)).to be_a(Typhoeus::Response)
      end
    end

    context 'when the request failed' do
      let(:response_code) { 500 }

      it 'doesn’t save the request in the Rails cache' do
        cache.set(request, response)
        expect(Rails.cache.exist?(request)).to be false
      end
    end
  end

  describe "#get" do
    it 'returns the request in the cache' do
      Rails.cache.write(request, response)
      expect(cache.get(request)).to be_a(Typhoeus::Response)
    end
  end
end
