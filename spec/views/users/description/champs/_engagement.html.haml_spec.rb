require 'spec_helper'

describe 'users/description/champs/engagement.html.haml', type: :view do
  let(:type_champ) { create(:type_de_champ_public, type_champ: :engagement) }

  subject { render 'users/description/champs/engagement.html.haml', champ: champ }

  context "when the value is on" do
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: "on").decorate }

    it { is_expected.to have_selector("input[type='checkbox'][checked]") }
  end

  context "when the value is nil" do
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: nil).decorate }

    it { is_expected.to have_selector("input[type='checkbox']") }
    it { is_expected.not_to have_selector("input[type='checkbox'][checked]") }
  end
end
