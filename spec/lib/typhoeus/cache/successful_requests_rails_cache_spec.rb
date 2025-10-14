# frozen_string_literal: true

describe Typhoeus::Cache::SuccessfulRequestsRailsCache, lib: true do
  let(:cache) { described_class.new }

  let(:base_url) { "localhost:3001" }
  let(:request) { Typhoeus::Request.new(base_url, { method: :get }) }
  let(:response) { Typhoeus::Response.new(response_code:, return_code: 0, mock: true, headers:) }
  let(:headers) { {} }

  let(:response_code) { 0 }

  around do |example|
    old_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = old_cache
  end

  describe "#set" do
    context 'when the request is successful' do
      let(:response_code) { 200 }

      context 'and the result is cacheable' do
        let(:headers) { { 'cache-control' => 'public, max-age=60' } }

        it 'saves the request in the Rails cache' do
          cache.set(request, response)
          expect(Rails.cache.exist?(request)).to be true
          expect(Rails.cache.read(request)).to be_a(Typhoeus::Response)
        end
      end

      context 'but the result is not cacheable' do
        let(:headers) { { 'cache-control' => 'private' } }

        it 'doesn’t save the request in the Rails cache' do
          cache.set(request, response)
          expect(Rails.cache.exist?(request)).to be false
        end
      end

      context 'but the result is not cacheable (in a multiple headers form)' do
        let(:headers) { { 'cache-control' => ['public', 'no-cache'] } }

        it 'doesn’t save the request in the Rails cache' do
          cache.set(request, response)
          expect(Rails.cache.read(to_key(request))).to be nil
        end
      end

      context 'but the result is as a max-age of 0' do
        let(:headers) { { 'cache-control' => 'public, max-age=0' } }

        it 'doesn’t save the request in the Rails cache' do
          cache.set(request, response)
          expect(Rails.cache.read(to_key(request))).to be nil
        end
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

  describe Typhoeus::Cache::SuccessfulRequestsRailsCache::CacheInfo do
    describe '#initialize' do
      it 'parses simple directives in mix cases and with extranous spaces' do
        cache_info = described_class.new(' Public  , Max-age=60  ')
        expect(cache_info.cacheable?).to be true
        expect(cache_info.expires_in).to eq(60)
      end

      it 'handles nil directives' do
        cache_info = described_class.new(nil)
        expect(cache_info.cacheable?).to be false
        expect(cache_info.expires_in).to eq(0)
      end
    end

    describe '#cacheable?' do
      it 'returns true when public directive is present' do
        cache_info = described_class.new('public')
        expect(cache_info.cacheable?).to be true
      end

      it 'returns false when no-store is present' do
        cache_info = described_class.new('public, no-store')
        expect(cache_info.cacheable?).to be false
      end

      it 'returns false when no-cache is present' do
        cache_info = described_class.new('public, no-cache')
        expect(cache_info.cacheable?).to be false
      end

      it 'returns false when public is not present' do
        cache_info = described_class.new('private, max-age=60')
        expect(cache_info.cacheable?).to be false
      end
    end

    describe '#expires_in' do
      it 'returns max-age value when present' do
        cache_info = described_class.new('public, max-age=3600')
        expect(cache_info.expires_in).to eq(3600)
      end

      it 'returns 0 when max-age is not present' do
        cache_info = described_class.new('public')
        expect(cache_info.expires_in).to eq(0)
      end

      it 'returns 0 when max-age is negative' do
        cache_info = described_class.new('public, max-age=-60')
        expect(cache_info.expires_in).to eq(0)
      end

      it 'clips max-age to MAX_AGE_LIMIT (1 day)' do
        cache_info = described_class.new('public, max-age=999999999')
        expect(cache_info.expires_in).to eq(1.day.to_i)
      end

      it 'handles malformed max-age' do
        cache_info = described_class.new('public, max-age=invalid')
        expect(cache_info.expires_in).to eq(0)
      end
    end
  end
end
