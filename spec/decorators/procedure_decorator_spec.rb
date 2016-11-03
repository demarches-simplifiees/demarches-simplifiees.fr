require 'spec_helper'

describe ProcedureDecorator do
  let(:procedure) { create(:procedure, :published,  created_at: Time.new(2015, 12, 24, 14, 10)) }
  subject { procedure.decorate }

  describe 'lien' do
    subject { super().lien }
    it { is_expected.to match(/fake_path/) }
  end

  describe 'created_at_fr' do
    subject { super().created_at_fr }
    it { is_expected.to eq('24/12/2015 14:10') }
  end

  describe 'logo_img' do
    subject { super().logo_img }
    it { is_expected.to eq(image_url(LOGO_NAME)) }
  end

  describe 'geographic_information' do
    subject { super().geographic_information }
    it { expect(subject.use_api_carto).to be_falsey }
    it { expect(subject.quartiers_prioritaires).to be_falsey }
    it { expect(subject.cadastre).to be_falsey }
  end

end