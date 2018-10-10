require 'spec_helper'

describe 'shared/dossiers/map.html.haml', type: :view do
  subject do
    render(partial: 'shared/dossiers/map.html.haml', locals: { dossier: dossier })
  end

  describe "javascript variables printing" do
    let(:dossier) { create(:dossier, json_latlngs: json_latlngs) }

    context 'with a correct json' do
      let(:json_latlngs) { "[[{\"lat\":50.659255436656736,\"lng\":3.080635070800781},{\"lat\":50.659255436656736,\"lng\":3.079690933227539},{\"lat\":50.659962770886516,\"lng\":3.0800342559814453},{\"lat\":50.659962770886516,\"lng\":3.0811500549316406},{\"lat\":50.659255436656736,\"lng\":3.080635070800781}]]" }

      before { subject }

      it { expect(rendered).to have_content('selection: [[{"lat":50.659255436656736,"lng":3.080635070800781},{"lat":50.659255436656736,"lng":3.079690933227539},{"lat":50.659962770886516,"lng":3.0800342559814453},{"lat":50.659962770886516,"lng":3.0811500549316406},{"lat":50.659255436656736,"lng":3.080635070800781}]],') }
    end

    context 'without a correct json' do
      let(:json_latlngs) { "dossier" }

      before { subject }

      it { expect(rendered).to have_content('selection: {},') }
    end
  end
end
