require_relative 'fillable-pdf/itext'
require_relative 'kernel'

class Field
  # PdfName has a constant "A" and a constant "a". Unfortunately, RJB does not differentiate
  # between these constants and tries to create the same constant ("A") for both, which causes
  # an annoying warning "already initialized constant Rjb::Com_itextpdf_kernel_pdf_PdfName::A".
  # As long as RJB has not fixed this issue, this warning will remain suppressed.
  suppress_warnings { PDF_NAME = Rjb.import('com.itextpdf.kernel.pdf.PdfName') } # rubocop:disable Lint/ConstantDefinitionInBlock

  BUTTON = PDF_NAME.Btn.toString
  CHOICE = PDF_NAME.Ch.toString
  SIGNATURE = PDF_NAME.Sig.toString
  TEXT = PDF_NAME.Tx.toString
end
