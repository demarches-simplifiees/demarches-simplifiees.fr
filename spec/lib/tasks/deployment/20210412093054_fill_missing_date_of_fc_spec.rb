describe '20210412093054_fill_missing_date_of_fc' do
  let(:rake_task) { Rake::Task['after_party:fill_missing_date_of_fc'] }

  let!(:user) { create(:user, created_at: Time.zone.parse('2000/01/01')) }

  let!(:valid_fci) do
    FranceConnectInformation.create!(
      user: user,
      france_connect_particulier_id: '123',
      created_at: Time.zone.parse('2010/01/01'),
      updated_at: Time.zone.parse('2012/01/01')
    )
  end

  let!(:missing_created_fci) do
    fci = FranceConnectInformation.create!(
      user: user,
      france_connect_particulier_id: '123',
      updated_at: Time.zone.parse('2013/01/01')
    )

    fci.update_column('created_at', nil)
    fci
  end

  let!(:missing_created_updated_fci) do
    fci = FranceConnectInformation.create!(
      user: user,
      france_connect_particulier_id: '123'
    )

    fci.update_column('created_at', nil)
    fci.update_column('updated_at', nil)
    fci
  end

  let!(:missing_created_updated_without_user_fci) do
    fci = FranceConnectInformation.create!(
      france_connect_particulier_id: '123'
    )

    fci.update_column('created_at', nil)
    fci.update_column('updated_at', nil)
    fci
  end

  before do
    rake_task.invoke
  end

  after { rake_task.reenable }

  it "does not change valid fci" do
    valid_fci.reload
    expect(valid_fci.created_at).to eq(Time.zone.parse('2010/01/01'))
    expect(valid_fci.updated_at).to eq(Time.zone.parse('2012/01/01'))
    expect(valid_fci.data).to be_nil
  end

  it "fills missing created from updated" do
    missing_created_fci.reload
    expect(missing_created_fci.created_at).to eq(Time.zone.parse('2013/01/01'))
    expect(missing_created_fci.data['note']).to eq("missing created_at has been copied from updated_at")
  end

  it "fills missing created, updated from users created" do
    missing_created_updated_fci.reload
    expect(missing_created_updated_fci.created_at).to eq(Time.zone.parse('2000/01/01'))
    expect(missing_created_updated_fci.updated_at).to eq(Time.zone.parse('2000/01/01'))
    expect(missing_created_updated_fci.data['note']).to eq("missing created_at, updated_at have been copied from users.created_at")
  end

  it "destroys fci when there is no user" do
    expect { missing_created_updated_without_user_fci.reload }
      .to raise_error(ActiveRecord::RecordNotFound)
  end
end
