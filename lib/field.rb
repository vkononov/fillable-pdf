require_relative 'fillable-pdf/itext'

class Field
  # PdfName has a constant "A" and a constant "a". Unfortunately, RJB does not differentiate
  # between these constants and tries to create the same constant ("A") for both, which causes
  # an annoying warning "already initialized constant Rjb::Com_itextpdf_kernel_pdf_PdfName::A".
  # As long as RJB has not fixed this issue, this warning will remain suppressed.

  BUTTON = ITEXT::PdfName.Btn.toString
  CHOICE = ITEXT::PdfName.Ch.toString
  SIGNATURE = ITEXT::PdfName.Sig.toString
  TEXT = ITEXT::PdfName.Tx.toString
end
