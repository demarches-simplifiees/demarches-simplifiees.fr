# frozen_string_literal: true

describe Champs::YesNoChamp do
  it_behaves_like "a boolean champ" do
    let(:boolean_champ) { build(:champ_yes_no, value: value) }
  end
end
