describe CarteController do
  describe '#show' do
    let(:service) { create(:service, departement: '63') }
    let(:service2) { create(:service, departement: '75') }
    let(:service3) { create(:service, departement: '75') }
    let!(:procedure) { create(:procedure, :published, service:, estimated_dossiers_count: 4) }
    let!(:procedure2) { create(:procedure, :published, service: service2, estimated_dossiers_count: 20, published_at: Date.parse('2020-07-14')) }
    let!(:procedure3) { create(:procedure, :published, service: service3, estimated_dossiers_count: 30, published_at: Date.parse('2021-07-14')) }
    let(:subject) { assigns(:map_filter) }

    it 'give stats for each departement' do
      get :show
      expect(subject.stats['63']).to eq({ nb_demarches: 1, nb_dossiers: 4 })
      expect(subject.stats['75']).to eq({ nb_demarches: 2, nb_dossiers: 50 })
    end

    it 'give stats for each departement for a specific year' do
      get :show, params: { map_filter: { year: 2020 } }
      expect(subject.stats['75']).to eq({ nb_demarches: 1, nb_dossiers: 20 })
    end

    it 'gracefully ignore invalid params' do
      get :show, params: { map_filter: { year: "not!" } }
      expect(subject.stats['75']).to eq({ nb_demarches: 2, nb_dossiers: 50 })

      get :show, params: { map_filter: { kind: "nimp" } }
      expect(subject.stats['75']).to eq({ nb_demarches: 2, nb_dossiers: 50 })
    end
  end
end
