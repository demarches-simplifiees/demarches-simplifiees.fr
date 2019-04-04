require 'spec_helper'

describe CarrierwaveActiveStorageMigrationService do
  describe '#hex_to_base64' do
    let(:service) { CarrierwaveActiveStorageMigrationService.new }

    it { expect(service.hex_to_base64('deadbeef')).to eq('3q2+7w==') }
  end
end
