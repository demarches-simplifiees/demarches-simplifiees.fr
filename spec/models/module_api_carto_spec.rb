require 'spec_helper'

describe ModuleAPICarto do
  describe 'assocations' do
    it { is_expected.to belong_to(:procedure) }
  end

  describe 'attributes' do
    it { is_expected.to have_db_column(:use_api_carto) }
    it { is_expected.to have_db_column(:quartiers_prioritaires) }
    it { is_expected.to have_db_column(:cadastre) }
  end

  describe '#classes' do
    let(:module_api_carto) { create(:module_api_carto, quartiers_prioritaires: qp, cadastre: cadastre) }

    context 'when module api carto qp is true' do
      let(:qp) { true }
      let(:cadastre) { false }

      subject { module_api_carto.classes }

      it { is_expected.to eq 'qp ' }
    end

    context 'when module api carto cadastre is true' do
      let(:qp) { false }
      let(:cadastre) { true }

      subject { module_api_carto.classes }

      it { is_expected.to eq 'cadastre ' }
    end

    context 'when module api carto qp is true and cadastre is true' do
      let(:qp) { true }
      let(:cadastre) { true }

      subject { module_api_carto.classes }

      it { is_expected.to eq 'qp cadastre ' }
    end

    context 'when module api carto qp is false and cadastre is false' do
      let(:qp) { false }
      let(:cadastre) { false }

      subject { module_api_carto.classes }

      it { is_expected.to eq '' }
    end
  end
end
