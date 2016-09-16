require 'rjb'
require 'securerandom'

# http://github.com/itext/itextpdf/releases/latest
Rjb::load(File.expand_path('../ext/itextpdf-5.5.9.jar', __dir__))


class FillablePDF

  # required Java imports
  BYTE_STREAM = Rjb::import('java.io.ByteArrayOutputStream')
  FILE_READER = Rjb::import('com.itextpdf.text.pdf.PdfReader')
  PDF_STAMPER = Rjb::import('com.itextpdf.text.pdf.PdfStamper')


  ##
  # Opens a given fillable PDF file and prepares it for modification.
  #
  #   @param [String] file the name of the PDF file or file path
  #
  def initialize(file)
    @file    = file
    @byte_stream = BYTE_STREAM.new
    @pdf_stamper = PDF_STAMPER.new FILE_READER.new(@file), @byte_stream
    @form_fields = @pdf_stamper.getAcroFields
  end


  ##
  # Retrieves the value of a field given its unique field name.
  #
  #   @param [String] key the field name
  #
  #   @return the value of the field
  #
  def get_field(key)
    @form_fields.getField key.to_s
  end


  ##
  # Sets the value of a field given its unique field name and value.
  #
  #   @param [String] key the field name
  #   @param [String] value the field value
  #
  def set_field(key, value)
    @form_fields.setField key.to_s, value.to_s
  end


  ##
  # Sets the values of multiple fields given a set of unique field names and values.
  #
  #   @param [Hash] fields the set of field names and values
  #
  def set_fields(fields)
    fields.each { |key, value| set_field key, value }
  end


  ##
  # Overwrites the previously opened PDF file and flattens it if requested.
  #
  #   @param [bool] flatten true if PDF should be flattened, false otherwise
  #
  def save(flatten = false)
    tmp_file = SecureRandom.uuid
    save_as(tmp_file, flatten)
    File.rename tmp_file, @file
  end


  ##
  # Saves the filled out PDF file with a given file and flattens it if requested.
  #
  #   @param [String] file the name of the PDF file or file path
  #   @param [bool] flatten true if PDF should be flattened, false otherwise
  #
  def save_as(file, flatten = false)
    File.open(file, 'wb') { |f| f.write finalize flatten and f.close }
  end


  private

  ##
  # Writes the contents of the modified fields to the previously opened PDF file.
  #
  #   @param [bool] flatten true if PDF should be flattened, false otherwise
  #
  def finalize(flatten)
    @pdf_stamper.setFormFlattening flatten
    @pdf_stamper.close
    @byte_stream.toByteArray
  end

end