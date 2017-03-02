require 'spec_helper'

describe PreremplissageService do

  let(:dossier) { create(:dossier) }
  let(:inject) { '{"Description":"préremplie"}' }
  let(:preremplissage_service) { PreremplissageService.new }

  describe '#parse_into' do
    subject { preremplissage_service.parse_into(inject,{}) }
    it { is_expected.to include(inject: {"Description" => "préremplie"}) }
  end

  describe '#fill_from' do
    let(:injected) { preremplissage_service.parse_into(inject,{}) }
    subject { preremplissage_service.fill_from(injected,dossier) }
    it { expect(dossier.champs.count).to eq(1) }
    it { expect(dossier.champs.first.libelle).to eq("Description") }
    it { expect(subject.champs.first.value).to eq("préremplie") }
  end

end
