AUTHORIZED_PDF_TYPES = [
  'application/pdf', # text x 4628654
  'application/x-pdf', # text x 30
  'image/pdf', # text x 23
  'text/pdf' # text x 12
]

AUTHORIZED_IMAGE_TYPES = [
  'image/jpeg', # multimedia x 1467465
  'image/png', # multimedia x 126662
  'image/tiff', # multimedia x 3985
  'image/bmp', # multimedia x 3656
  'image/webp', # multimedia x 529
  'image/gif', # multimedia x 463
  'image/vnd.dwg' # multimedia x 137 auto desk
]

AUTHORIZED_CONTENT_TYPES = AUTHORIZED_IMAGE_TYPES + AUTHORIZED_PDF_TYPES + [
  # multimedia
  'video/mp4', # multimedia x 2075
  'video/quicktime', # multimedia x 486
  'video/3gpp', # multimedia x 216
  'audio/mpeg', # multimedia x 26
  'video/x-ms-wm', # multimedia x 15 video microsoft ?
  'audio/mp4', # audio .mp4, .m4a
  'audio/x-m4a', # audio .m4a
  'audio/aac', # audio .aac
  'audio/x-wav', # audio .wav

  # application / program
  'application/json', # program x 6653577
  'application/zip', # program x 25831
  'application/octet-stream', # program x 8923 autodesk, citadel
  'text/x-adasrc', # program x 5116 agricultaral data
  'application/x-ole-storage', # program x 5015 msg message microsoft
  'application/x-zip-compressed', # program x 3242
  'text/csv', # program x 1901
  'message/rfc822', # program x 1622 .msg
  'application/x-7z-compressed', # program x 1359
  'application/vnd.rar', # program x 1344
  'application/x-x509-ca-cert', # program x 631
  'application/xml', # program x 314
  'text/x-log', # program x 188
  'application/gpx+xml', # program x 51
  'binary/octet-stream', # program x 48
  'application/octetstream', # program x 41
  'application/postscript', # program x 38
  'application/x-rar', # program x 37
  'octet/stream', # program x 33
  'text/tab-separated-values', # program x 30
  'application/gzip', # program x 24
  'application/x-dbf', # inconnu x 24 dbase table file format (dbf)
  'applicaton/octet-stream', # program x 17
  'application/vnd.google-earth.kml+xml', # autre x 10 transfert de point google
  'text/xml', # program x 10

  # text / sheet / presentation
  'application/vnd.ms-excel', # text x 166674
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document', # text x 103879
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', # text x 86336
  'application/vnd.oasis.opendocument.text', # text x 46229
  'application/msword', # text x 30167
  'text/plain', # text x 24477
  'application/vnd.oasis.opendocument.spreadsheet', # text x 15218
  'application/vnd.openxmlformats-officedocument.presentationml.presentation', # text x 3231
  'application/vnd.ms-excel.sheet.macroenabled.12', # text x 1487
  'application/rtf', # text x 1438
  'application/vnd.apple.pages', # text x 609
  'application/vnd.oasis.opendocument.graphics', # text x 535
  'application/vnd.ms-powerpoint', # text x 363
  'application/vnd.oasis.opendocument.presentation', # text x 169
  'application/oxps', # inconnu x 149 openxml ?
  'application/vnd.apple.numbers', # text x 144
  'application/x-iwork-pages-sffpages', # text x 139
  'application/vnd.ms-publisher', # text x 100
  'application/vnd.oasis.opendocument.text-template', # text x 100
  'application/vnd.openxmlformats-officedocument.wordprocessingml.template', # text x 75
  'application/vnd.ms-word.document.macroenabled.12', # text x 61
  'application/vnd.openxmlformats-officedocument.spreadsheetml.template', # text x 59
  'application/vnd.openxmlformats-officedocument.presentationml.slideshow', # text x 32
  'application/kswps', # inconnu x 26 , text ?
  'application/x-iwork-numbers-sffnumbers', # text x 25
  'text/rtf', # text x 25
  'application/vnd.ms-xpsdocument', # text x 23
  'application/vnd.ms-excel.sheet.binary.macroenabled.12', # text x 21
  'application/vnd.ms-powerpoint.presentation.macroenabled.12', # text x 15
  'application/x-msword', # text x 15
  'application/vnd.oasis.opendocument.spreadsheet-template', # text x 14
  'application/vnd.oasis.opendocument.text-master', # text x 12
  'application/x-abiword', # text x 11
  'application/x-iwork-keynote-sffnumbers', # text x 11
  'application/x-iwork-keynote-sffkey', # text x 10
  'application/vnd.sun.xml.writer' # text x 10
]
