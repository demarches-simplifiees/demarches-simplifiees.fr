describe '20190819100424_clean_procedure_presentation_from_followers_gestionnaires.rake' do
  let(:rake_task) { Rake::Task['after_party:clean_procedure_presentation_from_followers_gestionnaires'] }

  let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
  let(:assign_to) { create(:assign_to, procedure: procedure) }

  let!(:procedure_presentation) do
    pp = ProcedurePresentation.new(
      assign_to: assign_to,
      sort: {
        "order" => "asc",
        "table" => "followers_gestionnaires",
        "column" => "email"
      },
      filters: {
        "tous" => [],
        "suivis" => [],
        "traites" => [{
          "label" => "Email instructeur",
          "table" => "followers_gestionnaires",
          "value" => "mail@simon.lehericey.net",
          "column" => "email"
        }
        ],
        "a-suivre" => [],
        "archives" => []
      },
      displayed_fields: [
        {
          "column" => "email",
          "label" => "Demandeur",
          "table" => "user"
        },
        {
          "column" => "email",
          "label" => "Email instructeur",
          "table" => "followers_gestionnaires"
        }
      ]
    )
    pp.save(validate: false)
    pp
  end

  before do
    rake_task.invoke
    procedure_presentation.reload
  end

  after { rake_task.reenable }

  it do
    expect(procedure_presentation.displayed_fields[1]["table"]).to eq("followers_instructeurs")
    expect(procedure_presentation.sort["table"]).to eq("followers_instructeurs")
    expect(procedure_presentation.filters["traites"][0]["table"]).to eq("followers_instructeurs")
  end

  context 'with an invalid procedure_presentation' do
    let!(:procedure_presentation) do
      pp = ProcedurePresentation.new(
        assign_to: assign_to,
        filters: {
          "tous" => [],
          "suivis" => [],
          "traites" => [{
            "label" => "Email instructeur",
            "table" => "invalid table",
            "value" => "mail@simon.lehericey.net",
            "column" => "email"
          }
          ],
          "a-suivre" => [],
          "archives" => []
        },
        displayed_fields: []
      )
      pp.save(validate: false)
      pp
    end

    it 'does not stop the script' do
    end
  end
end
