describe '20190410131747_migrate_mail_body_to_actiontext.rake' do
  let(:rake_task) { Rake::Task['after_party:migrate_mail_body_to_actiontext'] }

  let!(:closed_mail) { create(:closed_mail, body: body) }

  before do
    rake_task.invoke
    closed_mail.reload
  end

  after { rake_task.reenable }

  context 'with a plain text body' do
    let(:body) { "Test de body" }

    it { expect(closed_mail.rich_body.to_plain_text).to eq(closed_mail.body) }
  end

  context 'with a html text body' do
    let(:body) { "Test de body<br>" }

    it { expect(closed_mail.rich_body.to_s.squish).to eq("<div class=\"trix-content\"> #{closed_mail.body} </div>".squish) }
  end
end
