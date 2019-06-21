module OperationLogsHelper
  def operation_download_button(attachment)
    link_to "Télécharger", rails_blob_path(attachment, disposition: "attachment"), class: 'button small'
  end

  def operation_checked_notice(title, expected, actual)
    content_tag('span', class: 'notice') do
      if actual == expected
        content_tag('span', '', class: 'icon accept')
      else
        content_tag('span', '', class: 'icon refuse')
      end + ' ' + title
    end
  end
end
