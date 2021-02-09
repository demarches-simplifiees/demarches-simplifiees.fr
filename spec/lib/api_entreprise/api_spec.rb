describe APIEntreprise::API do
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:token) { Rails.application.secrets.api_entreprise[:key] }

  describe '.entreprise' do
    subject { described_class.entreprise(siren, procedure_id) }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}/)
        .to_return(status: status, body: body)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    context 'when the service throws a bad gateaway exception' do
      let(:siren) { '111111111' }
      let(:status) { 502 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises_unavailable.json') }

      it 'raises APIEntreprise::API::Error::RequestFailed' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::BadGateway)
      end
    end

    context 'when siren does not exist' do
      let(:siren) { '111111111' }
      let(:status) { 404 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises_not_found.json') }

      it 'raises APIEntreprise::API::Error::ResourceNotFound' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ResourceNotFound)
      end
    end

    context 'when request has bad format' do
      let(:siren) { '111111111' }
      let(:status) { 400 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises_not_found.json') }

      it 'raises APIEntreprise::API::Error::BadFormatRequest' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::BadFormatRequest)
      end
    end

    context 'when siren infos are private' do
      let(:siren) { '111111111' }
      let(:status) { 403 }
      let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises_private.json') }

      it 'raises APIEntreprise::API::Error::ResourceNotFound' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ResourceNotFound)
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
        let(:token) { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c" }
        let(:procedure) { create(:procedure, api_entreprise_token: token) }
        let(:procedure_id) { procedure.id }

        it 'call api-entreprise with specfic token' do
          subject
          expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}/)
        end
      end

      context 'without specific token for procedure' do
        let(:procedure) { create(:procedure, api_entreprise_token: nil) }
        let(:procedure_id) { procedure.id }

        it 'call api-entreprise with specfic token' do
          subject
          expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}/)
        end
      end
    end
  end

  describe '.etablissement' do
    subject { described_class.etablissement(siret, procedure_id) }
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/etablissements\/#{siret}?.*non_diffusables=true/)
        .to_return(status: status, body: body)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    context 'when siret does not exist' do
      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises APIEntreprise::API::Error::ResourceNotFound' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ResourceNotFound)
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
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\//)
        .to_return(status: status, body: body)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    context 'when siret does not exist' do
      subject { described_class.exercices(siret, procedure_id) }

      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises APIEntreprise::API::Error::ResourceNotFound' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ResourceNotFound)
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
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\//)
        .to_return(status: status, body: body)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    subject { described_class.rna(siren, procedure_id) }

    context 'when siren does not exist' do
      let(:siren) { '111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises APIEntreprise::API::Error::ResourceNotFound' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ResourceNotFound)
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
      allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return(roles)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/attestations_sociales_acoss\/#{siren}/)
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
      allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return(roles)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/attestations_fiscales_dgfip\/#{siren}/)
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

  describe '.bilans_bdf' do
    let(:procedure) { create(:procedure, api_entreprise_token: token) }
    let(:siren) { '418166096' }
    let(:status) { 200 }
    let(:body) { File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf.json') }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return(roles)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/bilans_entreprises_bdf\/#{siren}/)
        .to_return(body: body, status: status)
    end

    subject { described_class.bilans_bdf(siren, procedure.id) }

    context 'when token not authorized' do
      let(:roles) { ["entreprises"] }

      it { expect(subject).to eq(nil) }
    end

    context 'when token is authorized' do
      let(:roles) { ["bilans_entreprise_bdf"] }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end

  describe 'with expired token' do
    let(:siren) { '111111111' }
    subject { described_class.entreprise(siren, procedure_id) }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(true)
    end

    it 'makes no call to api-entreprise' do
      subject
      expect(WebMock).not_to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}/)
    end
  end
end
