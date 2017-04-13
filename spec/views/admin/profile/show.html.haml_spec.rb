require 'spec_helper'

describe 'admin/profile/show.html.haml', type: :view do
  let(:token) { 'super_token' }
  let(:admin) { create(:administrateur, api_token: token) }
  before do
    assign(:administrateur, admin)
    render
  end
  it { expect(rendered).to have_content(token) }
end
