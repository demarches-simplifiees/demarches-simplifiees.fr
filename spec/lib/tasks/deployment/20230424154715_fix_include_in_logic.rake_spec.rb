describe '20230424154715_fix_include_in_logic.rake' do
  let(:rake_task) { Rake::Task['after_party:fix_include_in_logic'] }

  include Logic

  subject(:run_task) { rake_task.invoke }
  after { rake_task.reenable }

  context 'test condition correction' do
    let(:procedure) do
      types_de_champ_public = [
        { type: :multiple_drop_down_list },
        { type: :drop_down_list },
        { type: :integer_number },
        { type: :text }
      ]
      create(:procedure, :published, types_de_champ_public:)
    end

    def multiple_stable_id = procedure.reload.published_types_de_champ_public.first.stable_id
    def simple_stable_id = procedure.reload.published_types_de_champ_public.second.stable_id
    def integer_tdc = procedure.reload.published_types_de_champ_public.third
    def text_tdc = procedure.reload.published_types_de_champ_public.last

    before do
      and_condition = ds_and([
        # incorrect: should change ds_eq => ds_include
        ds_eq(champ_value(multiple_stable_id), constant("a")),
        # correct
        ds_include(champ_value(multiple_stable_id), constant("b")),
        # correct ds_eq because drop_down_list
        ds_eq(champ_value(simple_stable_id), constant("c"))
      ])

      text_tdc.update(condition: and_condition)

      or_condition = ds_or([
        # incorrect: should change ds_eq => ds_include
        ds_eq(champ_value(multiple_stable_id), constant("a"))
      ])

      integer_tdc.update(condition: or_condition)
    end

    it do
      run_task
      expected_and_condition = ds_and([
        ds_include(champ_value(multiple_stable_id), constant("a")),
        ds_include(champ_value(multiple_stable_id), constant("b")),
        ds_eq(champ_value(simple_stable_id), constant("c"))
      ])

      expect(text_tdc.condition).to eq(expected_and_condition)

      expected_or_condition = ds_or([
        ds_include(champ_value(multiple_stable_id), constant("a"))
      ])

      expect(integer_tdc.condition).to eq(expected_or_condition)
    end
  end

  context 'test revision scope' do
    let(:procedure) do
      types_de_champ_public = [
        { type: :drop_down_list, options: [:a, :b, :c] },
        { type: :text }
      ]
      create(:procedure, types_de_champ_public:)
    end

    let(:initial_condition) { ds_eq(champ_value(drop_down_stable_id), constant('a')) }

    def drop_down_stable_id = procedure.reload.draft_types_de_champ_public.first.stable_id
    def draft_text = procedure.reload.draft_types_de_champ_public.last
    def published_text = procedure.reload.published_types_de_champ_public.last

    before do
      draft_text.update(condition: initial_condition)

      procedure.publish!
      procedure.reload

      draft_drop_down = procedure.draft_revision.find_and_ensure_exclusive_use(drop_down_stable_id)
      draft_drop_down.update(type_champ: 'multiple_drop_down_list')
    end

    it do
      expect(draft_text.condition).to eq(initial_condition)
      expect(published_text.condition).to eq(initial_condition)

      run_task

      # the text condition is invalid for the draft revision
      expect(draft_text.condition).to eq(ds_include(champ_value(drop_down_stable_id), constant('a')))
      # the published_text condition is untouched as it s still valid
      expect(published_text.condition).to eq(initial_condition)
    end
  end

  context 'test champ change' do
    let!(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :multiple_drop_down_list, options: ['a'] }, { type: :text }]) }
    let!(:dossier) { create(:dossier, procedure:) }

    def multiple_stable_id = procedure.reload.published_types_de_champ_public.first.stable_id
    def text_tdc = procedure.reload.published_types_de_champ_public.last

    let(:initial_condition) { ds_eq(champ_value(multiple_stable_id), constant('a')) }
    let(:fixed_condition) { ds_include(champ_value(multiple_stable_id), constant('a')) }

    before do
      text_tdc.update(condition: initial_condition)
    end

    it do
      expect(dossier.reload.champs_public.last.type_de_champ.condition).to eq(initial_condition)

      run_task

      expect(dossier.reload.champs_public.last.type_de_champ.condition).to eq(fixed_condition)
    end
  end
end
