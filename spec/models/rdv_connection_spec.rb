# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RdvConnection, type: :model do
  describe '#expired?' do
    let(:rdv_connection) { build(:rdv_connection) }

    context 'when expires_at is in the past' do
      before do
        rdv_connection.expires_at = 1.hour.ago
      end

      it 'returns true' do
        expect(rdv_connection.expired?).to be true
      end
    end

    context 'when expires_at is in the future' do
      before do
        rdv_connection.expires_at = 1.hour.from_now
      end

      it 'returns false' do
        expect(rdv_connection.expired?).to be false
      end
    end

    context 'when expires_at is nil' do
      before do
        rdv_connection.expires_at = nil
      end

      it 'returns nil' do
        expect(rdv_connection.expired?).to be nil
      end
    end
  end
end
