require "rails_helper"

describe Rack::Attack, type: :request do
  let(:limit) { 5 }
  let(:period) { 20 }
  let(:ip) { "1.2.3.4" }

  before(:each) do
    setup_rack_attack_cache_store
    avoid_test_overlaps_in_cache
  end

  def setup_rack_attack_cache_store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  def avoid_test_overlaps_in_cache
    Rails.cache.clear
  end

  context '/users/sign_in' do
    before do
      limit.times do
        Rack::Attack.cache.count("/users/sign_in/ip:#{ip}", period)
      end
    end

    subject do
      post "/users/sign_in", headers: { 'X-Forwarded-For': ip }
    end

    it "throttle excessive requests by IP address" do
      subject

      expect(response).to have_http_status(:too_many_requests)
    end

    context 'when the ip is whitelisted' do
      before do
        allow(IPService).to receive(:ip_trusted?).and_return(true)
        allow_any_instance_of(Users::SessionsController).to receive(:create).and_return(:ok)
      end

      it "respects the whitelist" do
        subject

        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end
end
