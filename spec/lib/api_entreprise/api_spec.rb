describe ApiEntreprise::API do
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:token) { Rails.application.secrets.api_entreprise[:key] }

  describe '.entreprise' do
    subject { described_class.entreprise(siren, procedure_id) }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=#{token}/)
        .to_return(status: status, body: body)
    end

    context 'when the service is unavailable' do
      let(:siren) { '111111111' }
      let(:status) { 502 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises_unavailable.json') }

      it 'raises ApiEntreprise::API::RequestFailed' do
        expect { subject }.to raise_error(ApiEntreprise::API::RequestFailed)
      end
    end

    context 'when siren does not exist' do
      let(:siren) { '111111111' }
      let(:status) { 404 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises_not_found.json') }

      it 'raises ApiEntreprise::API::ResourceNotFound' do
        expect { subject }.to raise_error(ApiEntreprise::API::ResourceNotFound)
      end
    end

    context 'when siren infos are private' do
      let(:siren) { '111111111' }
      let(:status) { 403 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises_private.json') }

      it 'raises ApiEntreprise::API::ResourceNotFound' do
        expect { subject }.to raise_error(ApiEntreprise::API::ResourceNotFound)
      end
    end

    context 'when siren exist' do
      let(:siren) { '418166096' }
      let(:status) { 200 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises.json') }

      it 'returns response body' do
        expect(subject).to eq(JSON.parse(body, symbolize_names: true))
      end

      context 'with specific token for procedure' do
        let(:token) { 'token-for-demarche' }
        let(:procedure) { create(:procedure, api_entreprise_token: token) }
        let(:procedure_id) { procedure.id }

        it 'call api-entreprise with specfic token' do
          subject
          expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=token-for-demarche/)
        end
      end

      context 'without specific token for procedure' do
        let(:procedure) { create(:procedure, api_entreprise_token: nil) }
        let(:procedure_id) { procedure.id }

        it 'call api-entreprise with specfic token' do
          subject
          expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}?.*token=#{token}/)
        end
      end
    end
  end

  describe '.etablissement' do
    subject { described_class.etablissement(siret, procedure_id) }
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*non_diffusables=true&.*token=/)
        .to_return(status: status, body: body)
    end

    context 'when siret does not exist' do
      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises ApiEntreprise::API::ResourceNotFound' do
        expect { subject }.to raise_error(ApiEntreprise::API::ResourceNotFound)
      end
    end

    context 'when siret exists' do
      let(:siret) { '41816609600051' }
      let(:status) { 200 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }

      it 'returns body' do
        expect(subject).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.exercices' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/.*token=/)
        .to_return(status: status, body: body)
    end

    context 'when siret does not exist' do
      subject { described_class.exercices(siret, procedure_id) }

      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises ApiEntreprise::API::ResourceNotFound' do
        expect { subject }.to raise_error(ApiEntreprise::API::ResourceNotFound)
      end
    end

    context 'when siret exists' do
      subject { described_class.exercices(siret, procedure_id) }

      let(:siret) { '41816609600051' }
      let(:status) { 200 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/exercices.json') }

      it 'success' do
        expect(subject).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.rna' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\/.*token=/)
        .to_return(status: status, body: body)
    end

    subject { described_class.rna(siren, procedure_id) }

    context 'when siren does not exist' do
      let(:siren) { '111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises ApiEntreprise::API::ResourceNotFound' do
        expect { subject }.to raise_error(ApiEntreprise::API::ResourceNotFound)
      end
    end

    context 'when siren exists' do
      let(:siren) { '418166096' }
      let(:status) { 200 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end

  describe '.attestation_sociale' do
    let(:procedure) { create(:procedure, api_entreprise_token: token) }
    let(:siren) { '418166096' }
    let(:status) { 200 }
    let(:body) { File.read('spec/fixtures/files/api_entreprise/attestation_sociale.json') }

    before do
      allow_any_instance_of(Procedure).to receive(:api_entreprise_roles).and_return(roles)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/attestations_sociales_acoss\/#{siren}?.*token=/)
        .to_return(body: body, status: status)
    end

    subject { described_class.attestation_sociale(siren, procedure.id) }

    context 'when token not authorized' do
      let(:roles) { ["entreprises"] }

      it { expect(subject).to eq(nil) }
    end

    context 'when token is authorized' do
      let(:roles) { ["attestations_sociales"] }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end

  describe '.attestation_fiscale' do
    let(:procedure) { create(:procedure, api_entreprise_token: token) }
    let(:siren) { '418166096' }
    let(:user_id) { 1 }
    let(:status) { 200 }
    let(:body) { File.read('spec/fixtures/files/api_entreprise/attestation_fiscale.json') }

    before do
      allow_any_instance_of(Procedure).to receive(:api_entreprise_roles).and_return(roles)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/attestations_fiscales_dgfip\/#{siren}?.*token=#{token}&user_id=#{user_id}/)
        .to_return(body: body, status: status)
    end

    subject { described_class.attestation_fiscale(siren, procedure.id, user_id) }

    context 'when token not authorized' do
      let(:roles) { ["entreprises"] }

      it { expect(subject).to eq(nil) }
    end

    context 'when token is authorized' do
      let(:roles) { ["attestations_fiscales"] }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end
end
