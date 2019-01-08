require 'spec_helper'

describe RenderPartialService do
  let(:service) { RenderPartialService.new(controller, method) }
  let(:controller) { ApplicationController }
  let(:method) { :index }

  describe 'navbar' do
    subject { service.navbar }

    it { is_expected.to eq "layouts/navbars/navbar_#{controller.to_s.parameterize}_#{method}" }
  end

  describe 'left_panel' do
    subject { service.left_panel }

    it { is_expected.to eq "layouts/left_panels/left_panel_#{controller.to_s.parameterize}_#{method}" }
  end
end
