require_relative 'suppress_warnings'
require 'rjb'

Rjb.load(Dir.glob(File.expand_path('../../ext/*.jar', __dir__)).join(':'))

class FillablePDF
  module ITEXT
    extend FillablePDF::SuppressWarnings

    suppress_warnings do
      ByteArrayOutputStream = Rjb.import 'com.itextpdf.io.source.ByteArrayOutputStream'
      Canvas = Rjb.import 'com.itextpdf.layout.Canvas'
      Div = Rjb.import 'com.itextpdf.layout.element.Div'
      HorizontalAlignment = Rjb.import 'com.itextpdf.layout.properties.HorizontalAlignment'
      Image = Rjb.import 'com.itextpdf.layout.element.Image'
      ImageDataFactory = Rjb.import 'com.itextpdf.io.image.ImageDataFactory'
      PdfAcroForm = Rjb.import 'com.itextpdf.forms.PdfAcroForm'
      PdfDictionary = Rjb.import 'com.itextpdf.kernel.pdf.PdfDictionary'
      PdfDocument = Rjb.import 'com.itextpdf.kernel.pdf.PdfDocument'
      PdfFormXObject = Rjb.import 'com.itextpdf.kernel.pdf.xobject.PdfFormXObject'
      PdfName = Rjb.import 'com.itextpdf.kernel.pdf.PdfName'
      PdfReader = Rjb.import 'com.itextpdf.kernel.pdf.PdfReader'
      PdfWriter = Rjb.import 'com.itextpdf.kernel.pdf.PdfWriter'
      Rectangle = Rjb.import 'com.itextpdf.kernel.geom.Rectangle'
      VerticalAlignment = Rjb.import 'com.itextpdf.layout.properties.VerticalAlignment'
    end
  end
end
