# frozen_string_literal: true

RSpec.describe DossierTree::SectionsSummaryComponent, type: :component do
  subject { render_inline(component).to_html }

  let(:is_private) { false }
  let(:types_de_champ) do
    [
      { type: :header_section, level: 1 },
      { type: :text },
      { type: :header_section, level: 2 },
      { type: :repetition, children: [{ type: :text }, { type: :header_section, level: 1 }, { type: :text }] },
      { type: :header_section, level: 3 },
      { type: :text }
    ]
  end
  let(:procedure) { create(:procedure, types_de_champ_public: types_de_champ, types_de_champ_private: types_de_champ) }
  let(:revision) { procedure.draft_revision }
  let(:dossier) { nil }
  let(:tree) do
    if is_private && dossier
      dossier.private_tree(profile: 'instructeur')
    elsif is_private
      procedure.draft_private_tree
    elsif dossier
      dossier.public_tree(profile: 'instructeur')
    else
      procedure.draft_public_tree
    end
  end
  let(:component) { described_class.new(tree:, revision:) }
  let(:revision_types_de_champ) do
    (is_private ? procedure.active_revision.revision_types_de_champ_private : procedure.active_revision.revision_types_de_champ_public)
      .flat_map { _1.repetition? ? [] : _1 }
      .filter(&:header_section?)
  end

  context 'dossier' do
    let(:revision) { nil }
    let(:dossier) { create(:dossier, procedure:) }

    context 'public' do
      it do
        revision_types_de_champ.each { expect(subject).to have_selector("a[href='#section_#{_1.type_de_champ.stable_id}']") }
      end
    end

    context 'private' do
      let(:is_private) { true }
      it do
        revision_types_de_champ.each { expect(subject).to have_selector("a[href='#section_#{_1.type_de_champ.stable_id}']") }
      end
    end
  end

  context 'public' do
    it do
      revision_types_de_champ.each { expect(subject).to have_selector("a[href='##{ActionView::RecordIdentifier.dom_id(_1, :type_de_champ_editor)}']") }
    end
  end

  context 'private' do
    let(:is_private) { true }
    it do
      revision_types_de_champ.each { expect(subject).to have_selector("a[href='##{ActionView::RecordIdentifier.dom_id(_1, :type_de_champ_editor)}']") }
    end
  end
end
