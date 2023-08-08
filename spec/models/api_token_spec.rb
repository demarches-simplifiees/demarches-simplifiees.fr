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
      expect(api_token.write_access?).to eq(true)
      expect(api_token.procedure_ids).to eq([])
      expect(api_token.allowed_procedure_ids).to eq(nil)
      expect(api_token.context).to eq(administrateur_id: administrateur.id, procedure_ids: [], write_access: true)
      expect(api_token.full_access?).to be_truthy
    end

    context 'with read_only' do
      before { api_token.update(write_access: false) }
      it do
        expect(api_token.full_access?).to be_truthy
        expect(api_token.context).to eq(administrateur_id: administrateur.id, procedure_ids: [], write_access: false)
      end
    end

    context 'with procedure' do
      let(:procedure) { create(:procedure, administrateurs: [administrateur]) }
      before { procedure }

      it do
        expect(api_token.procedure_ids).to eq([procedure.id])
        expect(api_token.procedures_to_allow).to eq([procedure])
        expect(api_token.allowed_procedure_ids).to eq(nil)
        expect(api_token.context).to eq(administrateur_id: administrateur.id, procedure_ids: [procedure.id], write_access: true)
      end

      context 'update with procedure_id' do
        let(:procedure) { create(:procedure, administrateurs: [administrateur]) }
        let(:other_procedure) { create(:procedure, administrateurs: [administrateur]) }
        before { api_token.update(allowed_procedure_ids: [procedure.id]); other_procedure }

        it do
          expect(api_token.procedure_ids).to match_array([procedure.id, other_procedure.id])
          expect(api_token.procedures_to_allow).to eq([other_procedure])
          expect(api_token.allowed_procedure_ids).to eq([procedure.id])
          expect(api_token.context).to eq(administrateur_id: administrateur.id, procedure_ids: [procedure.id], write_access: true)
        end
      end

      context 'update with wrong procedure_id' do
        let(:other_administrateur) { create(:administrateur) }
        let(:procedure) { create(:procedure, administrateurs: [other_administrateur]) }
        before { api_token.update(allowed_procedure_ids: [procedure.id]) }

        it do
          expect(api_token.full_access?).to be_falsey
          expect(api_token.procedure_ids).to eq([])
          expect(api_token.procedures_to_allow).to eq([])
          expect(api_token.allowed_procedure_ids).to eq([])
          expect(api_token.context).to eq(administrateur_id: administrateur.id, procedure_ids: [], write_access: true)
        end
      end

      context 'update with destroyed procedure_id' do
        let(:procedure) { create(:procedure, administrateurs: [administrateur]) }
        before { api_token.update(allowed_procedure_ids: [procedure.id]); procedure.destroy }

        it do
          expect(api_token.full_access?).to be_falsey
          expect(api_token.procedure_ids).to eq([])
          expect(api_token.procedures_to_allow).to eq([])
          expect(api_token.allowed_procedure_ids).to eq([procedure.id])
          expect(api_token.context).to eq(administrateur_id: administrateur.id, procedure_ids: [], write_access: true)
        end
      end

      context 'update with detached procedure_id' do
        let(:other_procedure) { create(:procedure, administrateurs: [administrateur]) }
        let(:procedure) { create(:procedure, administrateurs: [administrateur]) }
        before { api_token.update(allowed_procedure_ids: [procedure.id]); other_procedure; administrateur.procedures.delete(procedure) }

        it do
          expect(api_token.full_access?).to be_falsey
          expect(api_token.procedure_ids).to eq([other_procedure.id])
          expect(api_token.allowed_procedure_ids).to eq([procedure.id])
          expect(api_token.context).to eq(administrateur_id: administrateur.id, procedure_ids: [], write_access: true)
        end
      end
    end

    context 'with procedure and allowed_procedure_ids' do
      let(:procedure) { create(:procedure, administrateurs: [administrateur]) }
      let(:other_procedure) { create(:procedure, administrateurs: [administrateur]) }

      before do
        api_token.update(allowed_procedure_ids: [procedure.id])
        other_procedure
      end

      it do
        expect(api_token.procedure_ids).to match_array([procedure.id, other_procedure.id])
        expect(api_token.allowed_procedure_ids).to eq([procedure.id])
        expect(api_token.context).to eq(administrateur_id: administrateur.id, procedure_ids: [procedure.id], write_access: true)
      end
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

    context "with valid garbage base64" do
      before { api_token.update(version: 1, encrypted_token: BCrypt::Password.create(token)) }

      let(:token) { "R5dAqE7nMxfMp93PcuuevDtn" }
      it { expect(result).to be_truthy }
    end
  end
end
