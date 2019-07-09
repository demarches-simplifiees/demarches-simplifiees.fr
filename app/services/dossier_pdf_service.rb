class DossierPdfService
  def self.build_pdf(dossier, path)
    action_view = ActionView::Base.new(ActionController::Base.view_paths,
      dossier: dossier)

    action_view.class_eval do
      include ApplicationHelper
      include DossierHelper
    end

    dossier_view = action_view.render(file: 'dossiers/show',
                                          formats: [:pdf])

    pdf = view_to_memory_file(dossier_view)

    File.open(path, 'w') do |f|
      f.puts(pdf.read)
    end
  end

  def self.view_to_memory_file(view)
    pdf = StringIO.new(view)
    pdf.set_encoding('UTF-8')

    def pdf.original_filename
      'dossier'
    end

    pdf
  end
end
