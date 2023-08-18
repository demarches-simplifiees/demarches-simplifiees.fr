# frozen_string_literal: true

require 'rails_helper'

describe AdminUpdateDefaultZonesJob, type: :job do
  let(:email) { 'louise@educ.pop.gouv.fr' }
  let(:admin) { create(:administrateur, email: email) }
  let(:hs_adapter) { double('hs_adapter', to_hs: 'agent.educpop.tchap.gouv.fr') }

  subject(:perform_job) { described_class.perform_now(admin) }

  before do
    allow(APITchap::HsAdapter).to receive(:new).with(email).and_return(hs_adapter)
    create(:zone, acronym: 'EP', tchap_hs: ['agent.educpop.tchap.gouv.fr'])
  end

  it 'update default zones' do
    perform_job
    expect(admin.default_zones.map(&:acronym)).to eq ['EP']
  end
end
