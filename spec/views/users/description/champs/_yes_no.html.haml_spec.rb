require 'spec_helper'

describe 'users/description/champs/yes_no.html.haml', type: :view do
  let(:type_champ) { create(:type_de_champ, type_champ: :yes_no) }

  before do
    render 'users/description/champs/yes_no.html.haml', champ: champ
  end

  context "when the value is Oui" do
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: "true").decorate }

    it 'should select the Oui radio button' do
      expect(rendered).to have_selector("input[value='true'][checked]")
    end
  end

  context "when the value is Non" do
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: "false").decorate }

    it 'should select the Non radio button' do
      expect(rendered).to have_selector("input[value='false'][checked]")
    end
  end
end
