# frozen_string_literal: true

describe ZxcvbnService do
  let(:password) { 'medium-strength-password' }
  subject(:service) { ZxcvbnService.new(password) }

  describe '#score' do
    it 'returns the password complexity score' do
      expect(service.score).to eq 3
    end
  end

  describe '#complexity' do
    it 'returns the password score, vulnerability and length' do
      expect(service.complexity).to eq [3, 'medium, strength, password', 24]
    end
  end

  describe 'caching' do
    it 'lazily caches the tester between calls and instances' do
      allow(Zxcvbn::Tester).to receive(:new).and_call_original
      allow(YAML).to receive(:safe_load).and_call_original

      first_service = ZxcvbnService.new('some-password')
      first_service.score
      first_service.complexity
      other_service = ZxcvbnService.new('other-password')
      other_service.score
      other_service.complexity

      expect(Zxcvbn::Tester).to have_received(:new).at_most(:once)
      expect(YAML).to have_received(:safe_load).at_most(:once)
    end

    it 'lazily caches the tester between threads' do
      allow(Zxcvbn::Tester).to receive(:new).and_call_original

      threads = 1.upto(4).map do
        Thread.new do
          ZxcvbnService.new(password).score
        end
      end.map(&:join)

      scores = threads.map(&:value)
      expect(scores).to eq([3, 3, 3, 3])
      expect(Zxcvbn::Tester).to have_received(:new).at_most(:once)
    end
  end
end
