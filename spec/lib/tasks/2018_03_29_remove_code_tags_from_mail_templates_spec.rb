require 'spec_helper'

describe '2018_03_29_remove_code_tags_from_mail_templates#clean' do
  let(:rake_task) { Rake::Task['2018_03_29_remove_code_tags_from_mail_templates:clean'] }

  let!(:dirty_closed_mail) { create(:closed_mail, body: "<h1>Salut</h1><br>Voici ton email avec une balise <code>--balise--</code>") }
  let!(:dirty_initiated_mail) { create(:initiated_mail, body: "<h1>Salut</h1><br>Voici ton email avec une balise <code>--balise--</code>") }
  let!(:dirty_received_mail) { create(:received_mail, body: "<h1>Salut</h1><br>Voici ton email avec une balise <code>--balise--</code>") }
  let!(:dirty_refused_mail) { create(:refused_mail, body: "<h1>Salut</h1><br>Voici ton email avec une balise <code>--balise--</code>") }
  let!(:dirty_without_continuation_mail) { create(:without_continuation_mail, body: "<h1>Salut</h1><br>Voici ton email avec une balise <code>--balise--</code>") }

  before do
    rake_task.invoke
    dirty_closed_mail.reload
    dirty_initiated_mail.reload
    dirty_received_mail.reload
    dirty_refused_mail.reload
    dirty_without_continuation_mail.reload
  end

  after { rake_task.reenable }

  it 'cleans up code tags' do
    expect(dirty_closed_mail.body).to eq("<h1>Salut</h1><br>Voici ton email avec une balise --balise--")
    expect(dirty_initiated_mail.body).to eq("<h1>Salut</h1><br>Voici ton email avec une balise --balise--")
    expect(dirty_received_mail.body).to eq("<h1>Salut</h1><br>Voici ton email avec une balise --balise--")
    expect(dirty_refused_mail.body).to eq("<h1>Salut</h1><br>Voici ton email avec une balise --balise--")
    expect(dirty_without_continuation_mail.body).to eq("<h1>Salut</h1><br>Voici ton email avec une balise --balise--")
  end
end
