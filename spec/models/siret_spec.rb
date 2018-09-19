require 'spec_helper'

describe Siret, type: :model do
  subject { Siret.new(siret: siret) }

  context 'with no siret provided' do
    let(:siret) { '' }

    it { is_expected.to be_invalid }
  end

  context 'with a siret that contains letters' do
    let(:siret) { 'A1B1C6D9E0F0G1' }

    it { is_expected.to be_invalid }
  end

  context 'with a siret that is too short' do
    let(:siret) { '1234567890' }

    it { is_expected.to be_invalid }
  end

  context 'with a siret that is too long' do
    let(:siret) { '12345678901234567890' }

    it { is_expected.to be_invalid }
  end

  context 'with a lunh-invalid siret' do
    let(:siret) { '41816609600052' }

    it { is_expected.to be_invalid }
  end

  context 'with a lunh-invalid La Poste siret' do
    let(:siret) { '35600000018723' }

    it { is_expected.to be_valid }
  end

  context 'with a valid siret' do
    let(:siret) { '41816609600051' }

    it { is_expected.to be_valid }
  end
end
