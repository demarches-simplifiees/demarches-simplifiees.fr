describe APIToken, type: :model do
  let(:administrateur) { create(:administrateur) }
  let(:api_token_and_packed_token) { APIToken.generate(administrateur) }
  let(:api_token) { api_token_and_packed_token.first }
  let(:packed_token) { api_token_and_packed_token.second }
  let(:plain_token) { APIToken.send(:unpack, packed_token)[:plain_token] }
  let(:packed_token_v2) { APIToken.send(:message_verifier).generate([administrateur.id, plain_token]) }

  describe '#generate' do
    it do
      expect(api_token.administrateur).to eq(administrateur)
      expect(api_token.prefix).to eq(packed_token.slice(0, 5))
      expect(api_token.version).to eq(3)
    end
  end

  describe '#find_and_verify' do
    let(:result) { APIToken.find_and_verify(token, administrateurs) }
    let(:token) { packed_token }
    let(:administrateurs) { [administrateur] }

    context 'without administrateur' do
      let(:administrateurs) { [] }

      context 'with packed token' do
        it { expect(result).to be_truthy }
      end

      context 'with packed token v2' do
        before { api_token.update(version: 2) }
        let(:token) { packed_token_v2 }
        it { expect(result).to be_truthy }
      end

      context 'with plain token' do
        before { api_token.update(version: 1) }
        let(:token) { plain_token }
        it { expect(result).to be_falsey }
      end
    end

    context 'with destroyed token' do
      before { api_token.destroy }

      context 'with packed token' do
        it { expect(result).to be_falsey }
      end

      context 'with packed token v2' do
        let(:token) { packed_token_v2 }
        it { expect(result).to be_falsey }
      end

      context 'with plain token' do
        let(:token) { plain_token }
        it { expect(result).to be_falsey }
      end
    end

    context 'with destroyed administrateur' do
      before { api_token.administrateur.destroy }
      let(:administrateurs) { [] }

      context 'with packed token' do
        it { expect(result).to be_falsey }
      end

      context 'with packed token v2' do
        let(:token) { packed_token_v2 }
        it { expect(result).to be_falsey }
      end

      context 'with plain token' do
        let(:token) { plain_token }
        it { expect(result).to be_falsey }
      end
    end

    context 'with other administrateur' do
      let(:other_administrateur) { create(:administrateur, :with_api_token) }
      let(:administrateurs) { [other_administrateur] }

      context 'with packed token' do
        it { expect(result).to be_truthy }
      end

      context 'with packed token v2' do
        before { api_token.update(version: 2) }

        let(:token) { packed_token_v2 }
        it { expect(result).to be_truthy }
      end

      context 'with plain token' do
        before { api_token.update(version: 1) }

        let(:token) { plain_token }
        it { expect(result).to be_falsey }
      end
    end

    context 'with many administrateurs' do
      let(:other_administrateur) { create(:administrateur, :with_api_token) }
      let(:other_api_token_and_packed_token) { APIToken.generate(other_administrateur) }
      let(:other_api_token) { other_api_token_and_packed_token.first }
      let(:other_packed_token) { other_api_token_and_packed_token.second }
      let(:other_plain_token) { APIToken.send(:unpack, other_packed_token)[:plain_token] }
      let(:administrateurs) { [administrateur, other_administrateur] }

      context 'with plain token' do
        before do
          api_token.update(version: 1)
          other_api_token.update(version: 1)
        end

        let(:token) { plain_token }
        it { expect(result).to be_truthy }

        context 'with other plain token' do
          let(:token) { other_plain_token }
          it { expect(result).to be_truthy }
        end
      end

      context 'with plain token (before migration)' do
        before do
          administrateur.update(encrypted_token: api_token.encrypted_token)
          other_administrateur.update(encrypted_token: other_api_token.encrypted_token)
          api_token.destroy
          other_api_token.destroy
        end

        let(:token) { plain_token }
        it { expect(result).to be_truthy }

        context 'with other plain token' do
          let(:token) { other_plain_token }
          it { expect(result).to be_truthy }
        end
      end
    end

    context 'with packed token' do
      it { expect(result).to be_truthy }
    end

    context 'with packed token v2' do
      before { api_token.update(version: 2) }

      let(:token) { packed_token_v2 }
      it { expect(result).to be_truthy }
    end

    context 'with plain token' do
      before { api_token.update(version: 1) }

      let(:token) { plain_token }
      it { expect(result).to be_truthy }
    end

    context 'with plain token (before migration)' do
      before do
        administrateur.update(encrypted_token: api_token.encrypted_token)
        api_token.destroy
      end

      let(:token) { plain_token }
      it { expect(result).to be_truthy }
    end

    context "with valid garbage base64" do
      before { api_token.update(version: 1, encrypted_token: BCrypt::Password.create(token)) }

      let(:token) { "R5dAqE7nMxfMp93PcuuevDtn" }
      it { expect(result).to be_truthy }
    end
  end
end
