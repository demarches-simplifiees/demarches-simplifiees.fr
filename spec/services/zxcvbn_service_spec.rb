# frozen_string_literal: true

describe ZxcvbnService do
  describe '.complexity' do
    it 'returns the password complexity score' do
      expect(ZxcvbnService.complexity(nil)).to eq 0
      expect(ZxcvbnService.complexity('motdepassefrançais')).to eq 1
      expect(ZxcvbnService.complexity(SECURE_PASSWORD)).to eq 4
    end
  end

  describe 'caching' do
    it 'lazily caches the tester between calls and instances' do
      allow(Zxcvbn::Tester).to receive(:new).and_call_original
      allow(YAML).to receive(:safe_load).and_call_original

      _first_call = ZxcvbnService.complexity('some-password')
      _other_call = ZxcvbnService.complexity('other-password')

      expect(Zxcvbn::Tester).to have_received(:new).at_most(:once)
      expect(YAML).to have_received(:safe_load).at_most(:once)
    end

    it 'lazily caches the tester between threads' do
      allow(Zxcvbn::Tester).to receive(:new).and_call_original

      threads = 1.upto(4).map do
        Thread.new do
          ZxcvbnService.complexity(SECURE_PASSWORD)
        end
      end.map(&:join)

      complexities = threads.map(&:value)
      expect(complexities).to eq([4, 4, 4, 4])
      expect(Zxcvbn::Tester).to have_received(:new).at_most(:once)
    end
  end
end
