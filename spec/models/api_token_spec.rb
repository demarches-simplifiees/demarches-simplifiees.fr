describe APIToken, type: :model do
  let(:administrateur) { create(:administrateur) }

  describe '#generate' do
    let(:api_token_and_packed_token) { APIToken.generate(administrateur) }
    let(:api_token) { api_token_and_packed_token.first }
    let(:packed_token) { api_token_and_packed_token.second }

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

  describe '#authenticate' do
    let(:api_token_and_packed_token) { APIToken.generate(administrateur) }
    let(:api_token) { api_token_and_packed_token.first }
    let(:packed_token) { api_token_and_packed_token.second }
    let(:bearer_token) { packed_token }

    subject { APIToken.authenticate(bearer_token) }

    context 'with the legit packed token' do
      it { is_expected.to eq(api_token) }
    end

    context 'with destroyed token' do
      before { api_token.destroy }

      it { is_expected.to be_nil }
    end

    context 'with destroyed administrateur' do
      before { api_token.administrateur.destroy }

      it { is_expected.to be_nil }
    end

    context "with a bearer token with the wrong plain_token" do
      let(:bearer_token) do
        clear_packed = [api_token.id, 'wrong'].join(';')
        Base64.urlsafe_encode64(clear_packed)
      end

      it { is_expected.to be_nil }
    end
  end
end
