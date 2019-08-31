require_relative 'fillable-pdf/itext'
require_relative 'field'
require 'securerandom'

class FillablePDF
  # required Java imports
  BYTE_STREAM = Rjb.import 'com.itextpdf.io.source.ByteArrayOutputStream'
  PDF_READER = Rjb.import 'com.itextpdf.kernel.pdf.PdfReader'
  PDF_WRITER = Rjb.import 'com.itextpdf.kernel.pdf.PdfWriter'
  PDF_DOCUMENT = Rjb.import 'com.itextpdf.kernel.pdf.PdfDocument'
  PDF_ACRO_FORM = Rjb.import 'com.itextpdf.forms.PdfAcroForm'
  PDF_FORM_FIELD = Rjb.import 'com.itextpdf.forms.fields.PdfFormField'

  ##
  # Opens a given fillable-pdf PDF file and prepares it for modification.
  #
  #   @param [String|Symbol] file_path the name of the PDF file or file path
  #
  def initialize(file_path)
    raise IOError, "File at `#{file_path}' is not found" unless File.exist?(file_path)
    @file_path = file_path
    @byte_stream = BYTE_STREAM.new
    @pdf_reader = PDF_READER.new @file_path
    @pdf_writer = PDF_WRITER.new @byte_stream
    @pdf_doc = PDF_DOCUMENT.new @pdf_reader, @pdf_writer
    @pdf_form = PDF_ACRO_FORM.getAcroForm(@pdf_doc, true)
    @form_fields = @pdf_form.getFormFields
  end

  ##
  # Determines whether the form has any fields.
  #
  #   @return true if form has fields, false otherwise
  #
  def any_fields?
    num_fields.positive?
  end

  ##
  # Returns the total number of form fields.
  #
  #   @return the number of fields
  #
  def num_fields
    @form_fields.size
  end

  ##
  # Retrieves the value of a field given its unique field name.
  #
  #   @param [String|Symbol] key the field name
  #
  #   @return the value of the field
  #
  def field(key)
    pdf_field(key).getValueAsString
  rescue NoMethodError
    raise "unknown key name `#{key}'"
  end

  ##
  # Retrieves the numeric type of a field given its unique field name.
  #
  #   @param [String|Symbol] key the field name
  #
  #   @return the type of the field
  #
  def field_type(key)
    pdf_field(key).getFormType.toString
  end

  ##
  # Retrieves a hash of all fields and their values.
  #
  #   @return the hash of field keys and values
  #
  def fields
    iterator = @form_fields.keySet.iterator
    map = {}
    while iterator.hasNext
      key = iterator.next.toString
      map[key.to_sym] = field(key)
    end
    map
  end

  ##
  # Sets the value of a field given its unique field name and value.
  #
  #   @param [String|Symbol] key the field name
  #   @param [String|Symbol] value the field value
  #
  def set_field(key, value)
    pdf_field(key).setValue(value.to_s)
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
  # Renames a field given its unique field name and the new field name.
  #
  #   @param [String|Symbol] old_key the field name
  #   @param [String|Symbol] new_key the field name
  #
  def rename_field(old_key, new_key)
    pdf_field(old_key).setFieldName(new_key.to_s)
  end

  ##
  # Removes a field from the document given its unique field name.
  #
  #   @param [String|Symbol] key the field name
  #
  def remove_field(key)
    @pdf_form.removeField(key.to_s)
  end

  ##
  # Returns a list of all field keys used in the document.
  #
  #   @return array of field names
  #
  def names
    iterator = @form_fields.keySet.iterator
    set = []
    set << iterator.next.toString.to_sym while iterator.hasNext
    set
  end

  ##
  # Returns a list of all field values used in the document.
  #
  #   @return array of field values
  #
  def values
    iterator = @form_fields.keySet.iterator
    set = []
    set << field(iterator.next.toString) while iterator.hasNext
    set
  end

  ##
  # Overwrites the previously opened PDF file and flattens it if requested.
  #
  #   @param [bool] flatten true if PDF should be flattened, false otherwise
  #
  def save(flatten: false)
    tmp_file = SecureRandom.uuid
    save_as(tmp_file, flatten: flatten)
    File.rename tmp_file, @file_path
  end

  ##
  # Saves the filled out PDF file with a given file and flattens it if requested.
  #
  #   @param [String] file_path the name of the PDF file or file path
  #   @param [Hash] flatten: true if PDF should be flattened, false otherwise
  #
  def save_as(file_path, flatten: false)
    File.open(file_path, 'wb') { |f| f.write(finalize(flatten: flatten)) && f.close }
  end

  private

  ##
  # Writes the contents of the modified fields to the previously opened PDF file.
  #
  #   @param [Hash] flatten: true if PDF should be flattened, false otherwise
  #
  def finalize(flatten: false)
    @pdf_form.flattenFields if flatten
    @pdf_doc.close
    @byte_stream.toByteArray
  end

  def pdf_field(key)
    field = @form_fields.get(key.to_s)
    raise "unknown key name `#{key}'" if field.nil?
    field
  end
end
