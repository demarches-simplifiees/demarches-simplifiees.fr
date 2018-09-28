require 'spec_helper'

describe ProcedureDecorator do
  let(:published_at) { Time.new(2017, 12, 24, 14, 12) }
  let(:procedure) { create(:procedure, published_at: published_at, created_at: Time.new(2015, 12, 24, 14, 10)) }
  let!(:procedure_path) { create(:procedure_path, administrateur: create(:administrateur), procedure: procedure) }

  subject { procedure.decorate }

  describe 'created_at_fr' do
    subject { super().created_at_fr }
    it { is_expected.to eq('24/12/2015 14:10') }
  end

  describe 'published_at_fr' do
    subject { super().published_at_fr }
    it { is_expected.to eq('24/12/2017 14:12') }

    context 'published_at is nil' do
      let(:published_at) { nil }
      it { is_expected.to eq(nil) }
    end
  end

  describe 'logo_img' do
    subject { super().logo_img }
    it { is_expected.to match(/http.*#{ActionController::Base.helpers.image_url("marianne.svg")}/) }
  end

  describe 'geographic_information' do
    subject { super().geographic_information }
    it { expect(subject.use_api_carto).to be_falsey }
    it { expect(subject.quartiers_prioritaires).to be_falsey }
    it { expect(subject.cadastre).to be_falsey }
  end
end
