describe APIParticulier::Services::SourcesService do
  describe "#sources" do
    let(:service) { described_class.new(procedure) }
    let(:procedure) { create(:procedure) }
    let(:api_particulier_scopes) { [] }
    let(:api_particulier_sources) { {} }

    before do
      procedure.update(api_particulier_scopes: api_particulier_scopes)
      procedure.update(api_particulier_sources: api_particulier_sources)
    end

    subject { service.available_sources }

    context 'when the procedure doesn’t have any available scopes' do
      it { is_expected.to eq({}) }
    end

    context 'when a procedure has a cnaf_allocataires and a cnaf_adresse scopes' do
      let(:api_particulier_scopes) { ['cnaf_allocataires', 'cnaf_enfants'] }

      let(:cnaf_allocataires_and_enfants) do
        {
          'cnaf' => {
            'allocataires' => ['noms_prenoms', 'date_de_naissance', 'sexe'],
            'enfants' => ['noms_prenoms', 'date_de_naissance', 'sexe']
          }
        }
      end

      it { is_expected.to match(cnaf_allocataires_and_enfants) }
    end
  end
end
