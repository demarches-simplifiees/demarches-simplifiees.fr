describe 'admin/assigns/show.html.haml', type: :view do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create :procedure, administrateur: admin }

  let(:assign_instructeurs) { procedure.defaut_groupe_instructeur.instructeurs }
  let(:not_assign_instructeurs) { admin.instructeurs.where.not(id: assign_instructeurs.ids) }

  before do
    assign(:procedure, procedure)
    assign(:instructeur, create(:instructeur))

    assign(:instructeurs_assign, (smart_listing_create :instructeurs_assign,
      assign_instructeurs,
      partial: "admin/assigns/list_assign",
      array: true))

    assign(:instructeurs_not_assign, (smart_listing_create :instructeurs_not_assign,
      not_assign_instructeurs,
      partial: "admin/assigns/list_not_assign",
      array: true))
  end

  context 'when admin have none instructeur ' do
    before do
      render
    end

    it { expect(rendered).to have_content('Aucun de disponible') }

    context 'when administrateur have none instructeur assign' do
      it { expect(rendered).to have_content('Aucun d\'affecté') }
    end
  end

  context 'when administrateur have two instructeur' do
    let!(:instructeur_1) { create :instructeur, email: 'plop@plop.com', administrateurs: [admin] }
    let!(:instructeur_2) { create :instructeur, email: 'plip@plop.com', administrateurs: [admin] }

    before do
      not_assign_instructeurs.reload
      assign_instructeurs.reload

      assign(:instructeurs_assign, (smart_listing_create :instructeurs_assign,
        assign_instructeurs,
        partial: "admin/assigns/list_assign",
        array: true))

      assign(:instructeurs_not_assign, (smart_listing_create :instructeurs_not_assign,
        not_assign_instructeurs,
        partial: "admin/assigns/list_not_assign",
        array: true))

      render
    end

    it { expect(rendered).to have_content(instructeur_1.email) }
    it { expect(rendered).to have_content(instructeur_2.email) }
  end
end
