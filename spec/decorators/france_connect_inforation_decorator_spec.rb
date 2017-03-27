require 'spec_helper'

describe FranceConnectInformationDecorator do
  let(:gender) { 'female' }
  let(:france_connect_information) { create :france_connect_information, gender: gender }

  subject { france_connect_information.decorate.gender_fr }

  context 'when france connect user is a male' do
    let(:gender) { 'male' }
    it { is_expected.to eq 'M.' }
  end

  context 'when france connect user is a female' do
    it { is_expected.to eq 'Mme' }
  end
end
