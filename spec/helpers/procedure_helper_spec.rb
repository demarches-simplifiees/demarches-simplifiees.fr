RSpec.describe ProcedureHelper, type: :helper do
  let(:procedure) { create(:procedure) }

  describe ".logo_img" do
    subject { logo_img(procedure) }

    it { is_expected.to match(/#{ActionController::Base.helpers.image_path("polynesie.png")}/) }
  end
end
