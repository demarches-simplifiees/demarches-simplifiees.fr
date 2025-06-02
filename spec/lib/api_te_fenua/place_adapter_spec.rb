# frozen_string_literal: true

require 'spec_helper'

describe APITeFenua::PlaceAdapter do
  describe '#suggestions' do
    let(:request) { 'Snack' }
    let(:status) { 200 }

    subject { described_class.new(request).suggestions }

    context 'when address return a list of places', vcr: "api_te_fenua_with_results" do
      let(:first_result) { { extent: [-149.52659305755, -17.524524300323, -149.526381601545, -17.5243388893143], :label => "Snack - Arue - Tahiti", :point => [-149.52648802799, -17.5244329728184] } }
      it { expect(subject.size).to eq 10 }
      it { is_expected.to be_an_instance_of Array }
      it { expect(subject[0]).to eq first_result }
    end

    context 'when address return an empty list', vcr: "api_te_fenua_without_result" do
      let(:request) { '####' }

      it { expect(subject.size).to eq 0 }
      it { is_expected.to be_an_instance_of Array }
    end

    context 'when BAN is unavailable' do
      before do
        stub_request(:get, API_TE_FENUA_URL + "/recherche?d=0&id=&q=#{request}&sid=reqId&x=0&y=0")
          .to_return(status: 503, body: '', headers: {})
      end

      it { expect(subject.size).to eq 0 }
      it { is_expected.to be_an_instance_of Array }
    end
  end
end
