# frozen_string_literal: true

describe APIEntreprise::API do
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:token) { nil }

  describe '.entreprise' do
    subject { described_class.new(procedure_id).entreprise(siren) }

    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/)
        .to_return(body: body, status: status)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    context 'when the service throws a bad gateaway exception' do
      let(:siren) { '111111111' }
      let(:status) { 502 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/entreprises_unavailable.json').read }

      it 'raises APIEntreprise::API::Error::BadGateway' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::BadGateway)
      end
    end

    context 'when the service reponds with 01000 code' do
      let(:siren) { '111111111' }
      let(:status) { 502 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/error_code_01000.json').read }

      it 'raises APIEntreprise::API::Error::ServiceUnavailable' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ServiceUnavailable)
      end
    end

    context 'when the service reponds with 01001 code' do
      let(:siren) { '111111111' }
      let(:status) { 502 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/error_code_01001.json').read }

      it 'raises APIEntreprise::API::Error::ServiceUnavailable' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ServiceUnavailable)
      end
    end

    context 'when the service reponds with 01002 code' do
      let(:siren) { '111111111' }
      let(:status) { 504 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/error_code_01002.json').read }

      it 'raises APIEntreprise::API::Error::ServiceUnavailable' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ServiceUnavailable)
      end
    end

    context 'when the service reponds with 02002 code' do
      let(:siren) { '111111111' }
      let(:status) { 504 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/error_code_02002.json').read }

      it 'raises APIEntreprise::API::Error::ServiceUnavailable' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ServiceUnavailable)
      end
    end

    context 'when the service reponds with 03002 code' do
      let(:siren) { '111111111' }
      let(:status) { 504 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/error_code_03002.json').read }

      it 'raises APIEntreprise::API::Error::ServiceUnavailable' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ServiceUnavailable)
      end
    end

    context 'when the service reponds with 03020 code' do
      let(:siren) { '111111111' }
      let(:status) { 503 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/error_code_03020.json').read }

      it 'raises APIEntreprise::API::Error::ServiceUnavailable' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ServiceUnavailable)
      end
    end

    context 'when siren does not exist' do
      let(:siren) { '111111111' }
      let(:status) { 404 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/entreprises_not_found.json').read }

      it 'raises APIEntreprise::API::Error::ResourceNotFound' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ResourceNotFound)
      end
    end

    context 'when request has bad format' do
      let(:siren) { '111111111' }
      let(:status) { 400 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/entreprises_not_found.json').read }

      it 'raises APIEntreprise::API::Error::BadFormatRequest' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::BadFormatRequest)
      end
    end

    context 'when siren infos are private' do
      let(:siren) { '111111111' }
      let(:status) { 403 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/entreprises_private.json').read }

      it 'raises APIEntreprise::API::Error::ResourceNotFound' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ResourceNotFound)
      end
    end

    context 'when siren exist' do
      let(:siren) { '418166096' }
      let(:status) { 200 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/entreprises.json').read }

      it 'returns response body' do
        expect(subject).to eq(JSON.parse(body, symbolize_names: true))
      end

      context 'with specific token for procedure' do
        let(:token) { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c" }
        let(:procedure) { create(:procedure, api_entreprise_token: token) }
        let(:procedure_id) { procedure.id }

        it 'call api-entreprise with specfic token' do
          subject
          expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/)
        end
      end

      context 'without specific token for procedure' do
        let(:procedure) { create(:procedure, api_entreprise_token: nil) }
        let(:procedure_id) { procedure.id }

        it 'call api-entreprise with specfic token' do
          subject
          expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/)
        end
      end

      context 'with a service without siret' do
        let(:procedure) { create(:procedure, :with_service) }
        let(:dinum_siret) { "13002526500013" }
        it 'send default recipient' do
          ENV["API_ENTREPRISE_DEFAULT_SIRET"] = dinum_siret
          procedure.service.siret = nil
          procedure.service.save(validate: false)
          subject
          expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/).with(query: hash_including({ recipient: dinum_siret }))
        end
      end

      context 'with a service with siret' do
        context 'with a siren entreprise not equivalent to siret service' do
          let(:procedure) { create(:procedure, :with_service) }
          it 'send default recipient' do
            subject
            expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/).with(query: hash_including({ recipient: procedure.service.siret }))
          end
        end

        context 'with a siren entreprise equivalent to siret service' do
          let(:procedure) { create(:procedure, :with_service) }
          let(:siren) { procedure.service.siret[0..8] }
          let(:dinum_siret) { "13002526500013" }
          it 'send default recipient' do
            ENV["API_ENTREPRISE_DEFAULT_SIRET"] = dinum_siret
            subject
            expect(WebMock).to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/).with(query: hash_including({ recipient: dinum_siret }))
          end
        end
      end
    end
  end

  describe '.etablissement' do
    subject { described_class.new(procedure_id).etablissement(siret) }
    before do
      stub_request(:get, "https://entreprise.api.gouv.fr/v3/insee/sirene/etablissements/#{siret}")
        .with(query: { "non_diffusables" => "true", "context" => APPLICATION_NAME, "object" => "procedure_id: #{procedure_id}", "recipient" => ENV.fetch("API_ENTREPRISE_DEFAULT_SIRET") })
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
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/etablissements.json').read }

      it 'returns body' do
        expect(subject).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.exercices' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/dgfip\/etablissements\/#{siret}\/chiffres_affaires/)
        .to_return(status: status, body: body)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    context 'when siret does not exist' do
      subject { described_class.new(procedure_id).exercices(siret) }

      let(:siret) { '11111111111111' }
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises APIEntreprise::API::Error::ResourceNotFound' do
        expect { subject }.to raise_error(APIEntreprise::API::Error::ResourceNotFound)
      end
    end

    context 'when siret exists' do
      subject { described_class.new(procedure_id).exercices(siret) }

      let(:siret) { '41816609600051' }
      let(:status) { 200 }
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/exercices.json').read }

      it 'success' do
        expect(subject).to eq(JSON.parse(body, symbolize_names: true))
      end
    end
  end

  describe '.rna' do
    before do
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/djepva\/api-association\/associations\/open_data\/#{siren}/)
        .to_return(status: status, body: body)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
    end

    subject { described_class.new(procedure_id).rna(siren) }

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
      let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/associations.json').read }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end

  describe '.attestation_sociale' do
    let(:procedure) { create(:procedure, api_entreprise_token: token) }
    let(:siren) { '418166096' }
    let(:status) { 200 }
    let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/attestation_sociale.json').read }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:can_fetch_attestation_sociale?).and_return(can_fetch)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/urssaf\/unites_legales\/#{siren}\/attestation_vigilance/)
        .to_return(body: body, status: status)
    end

    subject { described_class.new(procedure.id).attestation_sociale(siren) }

    context 'when token not authorized' do
      let(:can_fetch) { false }

      it { expect(subject).to eq(nil) }
    end

    context 'when token is authorized' do
      let(:can_fetch) { true }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end

  describe '.attestation_fiscale' do
    let(:procedure) { create(:procedure, api_entreprise_token: token) }
    let(:siren) { '418166096' }
    let(:user_id) { 1 }
    let(:status) { 200 }
    let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/attestation_fiscale.json').read }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:can_fetch_attestation_fiscale?).and_return(can_fetch)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/dgfip\/unites_legales\/#{siren}\/attestation_fiscale/)
        .to_return(body: body, status: status)
    end

    subject { described_class.new(procedure.id).attestation_fiscale(siren, user_id) }

    context 'when token not authorized' do
      let(:can_fetch) { false }

      it { expect(subject).to eq(nil) }
    end

    context 'when token is authorized' do
      let(:can_fetch) { true }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end

  describe '.bilans_bdf' do
    let(:procedure) { create(:procedure, api_entreprise_token: token) }
    let(:siren) { '418166096' }
    let(:status) { 200 }
    let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf.json').read }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:can_fetch_bilans_bdf?).and_return(can_fetch)
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
      stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/banque_de_france\/unites_legales\/#{siren}\/bilans/)
        .to_return(body: body, status: status)
    end

    subject { described_class.new(procedure.id).bilans_bdf(siren) }

    context 'when token not authorized' do
      let(:can_fetch) { false }

      it { expect(subject).to eq(nil) }
    end

    context 'when token is authorized' do
      let(:can_fetch) { true }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end

  describe '.privileges' do
    let(:api) { described_class.new }
    let(:status) { 200 }
    let(:body) { Rails.root.join('spec/fixtures/files/api_entreprise/privileges.json').read }
    subject { api.privileges }

    before do
      api.token = APIEntrepriseToken.new(token)

      allow(api.token).to receive(:jwt_token).and_return(double(blank?: blank))
      allow(api.token).to receive(:expired?).and_return(expired)

      stub_request(:get, "https://entreprise.api.gouv.fr/privileges")
        .to_return(body: body, status: status)
    end

    context 'with a blank token' do
      let(:blank) { true }
      let(:expired) { false }

      it { expect { subject }.to raise_error(APIEntrepriseToken::TokenError) }
    end

    context 'with a expired token' do
      let(:blank) { false }
      let(:expired) { true }

      it { expect { subject }.to raise_error(APIEntrepriseToken::TokenError) }
    end

    context 'with a valid token' do
      let(:blank) { false }
      let(:expired) { false }

      it { expect(subject).to eq(JSON.parse(body, symbolize_names: true)) }
    end
  end

  describe 'with expired token' do
    let(:siren) { '111111111' }
    subject { described_class.new(procedure_id).entreprise(siren) }

    before do
      allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(true)
    end

    it 'makes no call to api-entreprise' do
      expect { subject }.to raise_error(APIEntrepriseToken::TokenError)
      expect(WebMock).not_to have_requested(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}/)
    end
  end
end
