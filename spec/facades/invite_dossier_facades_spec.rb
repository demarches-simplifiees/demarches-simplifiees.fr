require 'spec_helper'

describe InviteDossierFacades do

  let(:dossier) { create :dossier }
  let(:email) { 'email@octo.com' }

  subject { described_class.new dossier.id, email }

  before do
    create :invite, email: email, dossier: dossier
  end

  it { expect(subject.dossier).to eq dossier }
end