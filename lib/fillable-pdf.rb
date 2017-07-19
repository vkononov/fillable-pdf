require_relative 'fillable-pdf/itext'
require_relative 'field'
require 'securerandom'


class FillablePDF
  # required Java imports
  BYTE_STREAM = Rjb.import('java.io.ByteArrayOutputStream')
  FILE_READER = Rjb.import('com.itextpdf.text.pdf.PdfReader')
  PDF_STAMPER = Rjb.import('com.itextpdf.text.pdf.PdfStamper')

  ##
  # Opens a given fillable PDF file and prepares it for modification.
  #
  #   @param [String] file the name of the PDF file or file path
  #
  def initialize(file)
    @file = file
    @byte_stream = BYTE_STREAM.new
    @pdf_stamper = PDF_STAMPER.new FILE_READER.new(@file), @byte_stream
    @acro_fields = @pdf_stamper.getAcroFields
  end

  ##
  # Determines whether the form has any fields.
  #
  #   @return true if form has fields, false otherwise
  #
  def any_fields?
    num_fields > 0
  end

  ##
  # Returns the total number of form fields.
  #
  #   @return the number of fields
  #
  def num_fields
    @acro_fields.getFields.size
  end

  ##
  # Retrieves the value of a field given its unique field name.
  #
  #   @param [String] key the field name
  #
  #   @return the value of the field
  #
  def get_field(key)
    @acro_fields.getField key.to_s
  end

  ##
  # Retrieves the numeric type of a field given its unique field name.
  #
  #   @param [String] key the field name
  #
  #   @return the type of the field
  #
  def get_field_type(key)
    @acro_fields.getFieldType key.to_s
  end

  ##
  # Retrieves a hash of all fields and their values.
  #
  #   @return the hash of field keys and values
  #
  def get_fields
    iterator = @acro_fields.getFields.keySet.iterator
    map = {}
    while iterator.hasNext
      key = iterator.next.toString
      map[key.to_sym] = get_field key
    end
    map
  end

  ##
  # Sets the value of a field given its unique field name and value.
  #
  #   @param [String] key the field name
  #   @param [String] value the field value
  #
  def set_field(key, value)
    @acro_fields.setField key.to_s, value.to_s
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
  #   @param [String] old_key the field name
  #   @param [String] new_key the field name
  #
  def rename_field(old_key, new_key)
    @acro_fields.renameField old_key.to_s, new_key.to_s
  end

  ##
  # Removes a field from the document given its unique field name.
  #
  #   @param [String] key the field name
  #
  def remove_field(key)
    @acro_fields.removeField key.to_s
  end

  ##
  # Returns a list of all field keys used in the document.
  #
  #   @return array of field names
  #
  def keys
    iterator = @acro_fields.getFields.keySet.iterator
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
    iterator = @acro_fields.getFields.keySet.iterator
    set = []
    set << get_field(iterator.next.toString) while iterator.hasNext
    set
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
    File.open(file, 'wb') { |f| f.write(finalize(flatten)) && f.close }
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
