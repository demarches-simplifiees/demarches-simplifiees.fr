describe 'users/description/champs/render_list_champs.html.haml', type: :view do
  let(:type_champ) { create(:type_de_champ_checkbox) }

  context "with any champ" do
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: nil) }

    before do
      render 'users/description/champs/render_list_champs.html.haml', champs: Champ.all, order_place: 0
    end

    it "should render the champ's libelle" do
      expect(rendered).to have_content(champ.libelle)
    end
  end

  context "with a checkbox champ" do
    context "whose value equals nil" do
      let!(:champ_checkbox_checked) { create(:champ, type_de_champ: type_champ, value: nil) }

      before do
        render 'users/description/champs/render_list_champs.html.haml', champs: Champ.all, order_place: 0
      end

      it 'should not render a checked checkbox' do
        expect(rendered).not_to have_css('input[type=checkbox][checked]')
      end
    end

    context "whose value equals 'on'" do
      let!(:champ_checkbox_checked) { create(:champ, type_de_champ: type_champ, value: 'on') }

      before do
        render 'users/description/champs/render_list_champs.html.haml', champs: Champ.all, order_place: 0
      end

      it 'should render a checked checkbox' do
        expect(rendered).to have_css('input[type=checkbox][checked]')
      end
    end
  end

  context 'with a dossier_link' do
    let(:type_champ) { create(:type_de_champ_dossier_link) }
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: nil) }

    before do
      render 'users/description/champs/render_list_champs.html.haml', champs: Champ.all, order_place: 0
    end

    it 'should render the _dossier_link partial' do
      expect(view).to render_template(partial: 'users/description/champs/_dossier_link',
                                      locals: { champ: champ })
    end
  end
end
