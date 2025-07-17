# frozen_string_literal: true

RSpec.describe ChampValidateConcern do
  context "external_data" do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :rnf }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champs.first }

    describe "waiting_for_external_data?" do
      context "pending" do
        before { champ.update(external_id: 'external_id') }
        it { expect(champ.waiting_for_external_data?).to be_truthy }
      end

      context "done" do
        before { champ.update_columns(external_id: 'external_id', data: 'some data') }
        it { expect(champ.waiting_for_external_data?).to be_falsey }
      end
    end

    describe "external_data_fetched?" do
      context "pending" do
        it { expect(champ.external_data_fetched?).to be_falsey }
      end

      context "done" do
        before { champ.update_columns(external_id: 'external_id', data: 'some data') }
        it { expect(champ.external_data_fetched?).to be_truthy }
      end
    end

    describe "fetch_external_data" do
      context "cleanup_if_empty" do
        before { champ.update_columns(data: 'some data') }

        it "remove data if external_id changes" do
          expect(champ.data).to_not be_nil
          champ.update(external_id: 'external_id')
          expect(champ.data).to be_nil
        end
      end

      context "fetch_external_data_later" do
        let(:data) { { address: { city: "some external data" } }.with_indifferent_access }

        it "fill data from external source" do
          expect_any_instance_of(Champs::RNFChamp).to receive(:fetch_external_data) { data }

          perform_enqueued_jobs do
            champ.update(external_id: 'external_id')
          end
          expect(champ.reload.data).to eq data
        end
      end
    end
  end

  describe '#save_external_exception' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :rnf }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champs.first }
    context "add execption to the log" do
      it do
        champ.send(:save_external_exception, double(inspect: 'PAN'), 404)
        expect { champ.reload }.not_to raise_error
      end
    end
  end
end
