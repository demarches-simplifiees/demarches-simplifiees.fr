describe APITokensController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, administrateur: admin) }

  before { sign_in(admin.user) }

  before { Timecop.freeze(Time.zone.local(2020, 1, 1, 12, 0, 0)) }
  after { Timecop.return }

  describe 'create' do
    let(:default_params) do
      {
        name: 'Test',
        access: 'read_write',
        target: 'all',
        lifetime: 'oneWeek'
      }
    end
    let(:token) { APIToken.last }

    subject { post :create, params: }

    before { subject }

    context 'with write access, no filtering, one week' do
      let(:params) { default_params }

      it 'creates a token' do
        expect(token.name).to eq('Test')
        expect(token.write_access?).to be true
        expect(token.full_access?).to be true
        expect(token.authorized_networks).to be_blank
        expect(token.expires_at).to eq(1.week.from_now.to_date)
      end
    end

    context 'with read access' do
      let(:params) { default_params.merge(access: 'read') }

      it { expect(token.write_access?).to be false }
    end

    context 'without network filtering but requiring infinite lifetime' do
      let(:params) { default_params.merge(lifetime: 'infinite') }

      it { expect(token.expires_at).to eq(1.week.from_now.to_date) }
    end

    context 'with bad network and infinite lifetime' do
      let(:networks) { 'bad' }
      let(:params) { default_params.merge(networkFiltering: 'customNetworks', networks:) }

      it do
        expect(token.authorized_networks).to be_blank
        expect(token.expires_at).to eq(1.week.from_now.to_date)
      end
    end

    context 'with network filtering' do
      let(:networks) { '192.168.1.23/32 2001:41d0:304:400::52f/128 bad' }
      let(:params) { default_params.merge(restriction: 'customNetworks', networks: ) }

      it {
  expect(token.authorized_networks).to eq([
    IPAddr.new('192.168.1.23/32'),
    IPAddr.new('2001:41d0:304:400::52f/128')
  ])
}
    end

    context 'with network filtering and infinite lifetime' do
      let(:networks) { '192.168.1.23/32 2001:41d0:304:400::52f/128' }
      let(:params) { default_params.merge(networkFiltering: 'customNetworks', networks:, lifetime: 'infinite') }

      it { expect(token.expires_at).to eq(nil) }
    end

    context 'with procedure filtering' do
      let(:params) { default_params.merge(target: 'custom', targets: [procedure.id]) }

      it do
        expect(token.allowed_procedure_ids).to eq([procedure.id])
        expect(token.full_access?).to be false
      end
    end

    context 'with procedure filtering on a procedure not owned by the admin' do
      let(:another_procedure) { create(:procedure) }
      let(:params) { default_params.merge(target: 'custom', targets: [another_procedure.id]) }

      it do
        expect(token.allowed_procedure_ids).to eq([])
        expect(token.full_access?).to be false
      end
    end
  end
end
