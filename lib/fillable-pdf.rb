require_relative 'fillable-pdf/itext'
require_relative 'field'
require 'base64'
require 'fileutils'
require 'securerandom'

class FillablePDF # rubocop:disable Metrics/ClassLength
  ##
  # Opens a given fillable-pdf PDF file and prepares it for modification.
  #
  #   @param [String|Symbol] file_path the name of the PDF file or file path
  #
  def initialize(file_path)
    raise IOError, "File <#{file_path}> is not found" unless File.exist?(file_path)
    @file_path = file_path
    begin
      @byte_stream = ITEXT::ByteArrayOutputStream.new
      @pdf_reader = ITEXT::PdfReader.new @file_path.to_s
      @pdf_reader.setUnethicalReading(true);
      @pdf_writer = ITEXT::PdfWriter.new @byte_stream
      @pdf_doc = ITEXT::PdfDocument.new @pdf_reader, @pdf_writer
      @pdf_form = ITEXT::PdfAcroForm.getAcroForm(@pdf_doc, true)
      @form_fields = @pdf_form.getFormFields
    rescue StandardError => e
      raise "#{e.message} (input file may be corrupt, incompatible, or may not have any forms)"
    end
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
  # Returns the total number of fillable form fields.
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
  # Sets an image within the bounds of the given form field. It doesn't matter
  # what type of form field it is (signature, image, etc). The image will be scaled
  # to fill the available space while preserving its aspect ratio. All previous
  # content will be removed, which means you cannot have both text and image.
  #
  #   @param [String|Symbol] key the field name
  #   @param [String|Symbol] file_path the name of the image file or image path
  #
  def set_image(key, file_path) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    raise IOError, "File <#{file_path}> is not found" unless File.exist?(file_path)
    field = pdf_field(key)
    widgets = field.getWidgets
    widget_dict = suppress_warnings { widgets.isEmpty ? field.getPdfObject : widgets.get(0).getPdfObject }
    orig_rect = widget_dict.getAsRectangle(ITEXT::PdfName.Rect)
    border_width = field.getBorderWidth
    bounding_rectangle = ITEXT::Rectangle.new(
      orig_rect.getWidth - (border_width * 2),
      orig_rect.getHeight - (border_width * 2)
    )

    pdf_form_x_object = ITEXT::PdfFormXObject.new(bounding_rectangle)
    canvas = ITEXT::Canvas.new(pdf_form_x_object, @pdf_doc)
    image = ITEXT::Image.new(ITEXT::ImageDataFactory.create(file_path.to_s))
                        .setAutoScale(true)
                        .setHorizontalAlignment(ITEXT::HorizontalAlignment.CENTER)
    container = ITEXT::Div.new
                          .setMargin(border_width).add(image)
                          .setVerticalAlignment(ITEXT::VerticalAlignment.MIDDLE)
                          .setFillAvailableArea(true)
    canvas.add(container)
    canvas.close

    pdf_dict = ITEXT::PdfDictionary.new
    widget_dict.put(ITEXT::PdfName.AP, pdf_dict)
    pdf_dict.put(ITEXT::PdfName.N, pdf_form_x_object.getPdfObject)
    widget_dict.setModified
  rescue StandardError => e
    raise "#{e.message} (there may be something wrong with your image)"
  end

  ##
  # Sets an image within the bounds of the given form field. It doesn't matter
  # what type of form field it is (signature, image, etc). The image will be scaled
  # to fill the available space while preserving its aspect ratio. All previous
  # content will be removed, which means you cannot have both text and image.
  #
  #   @param [String|Symbol] key the field name
  #   @param [String|Symbol] base64_image_data base64 encoded data image
  #
  def set_image_base64(key, base64_image_data)
    tmp_file = SecureRandom.uuid
    File.open(tmp_file, 'wb') { |f| f.write(Base64.decode64(base64_image_data)) }
    set_image(key, tmp_file)
  ensure
    FileUtils.rm tmp_file
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
  # Overwrites the previously opened PDF document and flattens it if requested.
  #
  #   @param [bool] flatten true if PDF should be flattened, false otherwise
  #
  def save(flatten: false)
    tmp_file = SecureRandom.uuid
    save_as(tmp_file, flatten: flatten)
    FileUtils.mv tmp_file, @file_path
  end

  ##
  # Saves the filled out PDF document in a given path and flattens it if requested.
  #
  #   @param [String] file_path the name of the PDF file or file path
  #   @param [Hash] flatten: true if PDF should be flattened, false otherwise
  #
  def save_as(file_path, flatten: false)
    if @file_path == file_path
      save(flatten: flatten)
    else
      File.open(file_path, 'wb') { |f| f.write(finalize(flatten: flatten)) && f.close }
    end
  end

  ##
  # Closes the PDF document discarding all unsaved changes.
  #
  # @return [Boolean] true if document is closed, false otherwise
  #
  def close
    @pdf_doc.close
    @pdf_doc.isClosed
  end

  private

  ##
  # Writes the contents of the modified fields to the previously opened PDF file.
  #
  #   @param [Hash] flatten: true if PDF should be flattened, false otherwise
  #
  def finalize(flatten: false)
    @pdf_form.flattenFields if flatten
    close
    @byte_stream.toByteArray
  end

  def pdf_field(key)
    field = @form_fields.get(key.to_s)
    raise "unknown key name `#{key}'" if field.nil?
    field
  end
end
