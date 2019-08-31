require_relative 'fillable-pdf/itext'

class Field
  PDF_NAME = Rjb.import('com.itextpdf.kernel.pdf.PdfName')

  BUTTON = PDF_NAME.Btn.toString
  CHOICE = PDF_NAME.Ch.toString
  SIGNATURE = PDF_NAME.Sig.toString
  TEXT = PDF_NAME.Tx.toString
end
