describe '20181120133842_remove_footer_from_email_templates.rake' do
  let(:rake_task) { Rake::Task['after_party:remove_footer_from_email_templates'] }
  let(:templates) do
    bodies.map { |body| create(:received_mail, body: body) }
  end

  before do
    templates
  end

  subject! do
    rake_task.invoke
  end

  after do
    rake_task.reenable
  end

  context 'when emails have "do not reply" footers' do
    let(:bodies) do
      [
        "<p>Some content</p>--- <br>\r\n<br>\r\nMerci de ne pas répondre à cet email. Postez directement vos questions dans\r\nvotre dossier sur la plateforme.</p>",
        "<p>Some content</p>-<br>\r\n<br>\r\nMerci de ne pas répondre à cet email. Postez directement vos questions dans\r\nvotre dossier sur la plateforme.</p>",
        "<p>Some content</p>— <br>\r\n<br>\r\nMerci de ne pas répondre à cet email. Postez directement vos questions dans\r\nvotre dossier sur la plateforme.</p>",
        "<p>Some content</p>--- <br>\r\n<br>\r\nMerci de ne pas répondre à cet email. Postez directement vos questions dans\r\nvotre dossier sur demarches-simplifiees.fr.</p>",
        "<p>Some content</p>— <br><br><small></small><b></b>Merci de ne pas répondre à cet email. Postez directement vos questions dans\r\nvotre dossier sur la plateforme.</p>",
        "<p>Some content</p>--- <br>\r\n<br>\r\nMerci de ne pas répondre à cet email. Postez directement vos questions dans\r\nvotre dossier --libelle-dossier--.</p>",
        "<p>Some content</p>--- <br>\r\n<br>\r\nMerci de ne pas répondre à cet email. Postez directement vos questions dans\r\nvotre dossier sur la plateforme, mais ne répondez pas à ce message.</p><p>\r\n\r\n</p><p>&nbsp;</p><p>\r\n<br></p><br>",
        "<p>Some content</p>--- <br>\r\n<br>\r\Veuillez ne pas répondre à cet email. Postez directement vos questions dans\r\nvotre dossier sur la plateforme.</p>",
        "<p>Some content</p>--- <br>\r\n<br>\r\nMerci\r\nde ne pas répondre à cet email. Postez directement vos questions dans\r\nvotre dossier sur la plateforme, mais ne répondez pas à ce message.</p><p>\r\n\r\n</p><p>&nbsp;</p><p>\r\n<br></p><br>",
        "<p>Some content</p>--- <br>\r\n<br>\r\Veuillez ne pas répondre à ce mail. Postez directement vos questions dans\r\nvotre dossier sur la plateforme.</p>"
      ]
    end

    it 'removes footer from mail template body' do
      templates.each do |template|
        expect(template.reload.body).to eq '<p>Some content</p>'
      end
    end
  end

  context 'when emails don’t have the standard boilerplate in the footer' do
    let(:bodies) do
      [
        "<p>Some content.</p><p>Merci, l'équipe demarches-simplifiees.fr.\r\n</p>",
        "<p>Some content.</p><p>Merci, l'équipe TPS.\r\n</p><small></small>"
      ]
    end

    it 'keeps the footer' do
      templates.each do |template|
        expect(bodies).to include(template.reload.body)
      end
    end
  end

  context 'when the footer contains some excluded strings' do
    let(:bodies) do
      [
        "<p>Some content</p>--- <br>\r\n<br>\r\nMerci de ne pas répondre à cet email. Le texte du présent e-mail n'a aucune valeur d'autorisation provisoire. Seule l'attestation d'autorisation provisoire de travail au format PDF, si délivrée, fera foi.",
        "<p>Some content</p>--- <br>\r\n<br>\r\nMerci de ne pas répondre à cet email. En cas de question, utilisez la messagerie ou écrivez à instructeur@exemple.gouv.fr.",
        "<p>Some content</p>--- <br>\r\n<br>Merci de ne pas répondre à cet email. Postez directement vos questions dans votre dossier sur la plateforme, ou trouvez le contact de votre conseiller cinéma sur <a target=\"_blank\" rel=\"nofollow\" href=\"http://www.cnc.fr/web/fr/conseillers-drac\">http://www.cnc.fr/web/fr/conseillers-drac</a><br>"
      ]
    end

    it 'keeps the footer' do
      templates.each do |template|
        expect(bodies).to include(template.reload.body)
      end
    end
  end
end
