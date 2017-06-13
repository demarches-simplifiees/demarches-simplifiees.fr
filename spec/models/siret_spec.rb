require 'spec_helper'

describe Siret, type: :model do
  let(:valid_siret) { '41816609600051' }
  let(:invalid_siret) { '111111111' }

  context 'with no siret provided' do
    it { is_expected.to validate_presence_of(:siret) }
  end

  context 'init with valid siret' do
    it { is_expected.to allow_value(valid_siret).for(:siret) }
  end

  context 'init with invalid siret' do
    it { is_expected.not_to allow_value(invalid_siret).for(:siret) }
  end

  context 'init with bullshit siret' do
    it { is_expected.not_to allow_value('bullshit').for(:siret) }
  end

  context 'init with a siret that is too long' do
    it { is_expected.not_to allow_value('9' * 15).for(:siret) }
  end
end
