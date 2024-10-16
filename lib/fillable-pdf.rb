require_relative 'fillable-pdf/itext'
require_relative 'fillable-pdf/suppress_warnings'
require_relative 'fillable-pdf/field'
require 'base64'
require 'securerandom'
require 'tmpdir'

class FillablePDF # rubocop:disable Metrics/ClassLength
  include SuppressWarnings

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
      @pdf_writer = ITEXT::PdfWriter.new @byte_stream
      @pdf_doc = ITEXT::PdfDocument.new @pdf_reader, @pdf_writer
      @pdf_form = ITEXT::PdfAcroForm.getAcroForm(@pdf_doc, true)
      @form_fields = @pdf_form.getAllFormFields
    rescue StandardError => e
      handle_pdf_open_error(e)
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
  # Retrieves the string type of a field given its unique field name.
  #
  #   @param [String|Symbol] key the field name
  #
  #   @return the type of the field
  #
  def field_type(key)
    pdf_field(key).getFormType&.toString
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
  #   @param [NilClass|TrueClass|FalseClass] generate_appearance true to generate appearance, false to let the PDF viewer application generate form field appearance, nil (default) to let iText decide what's appropriate
  #
  def set_field(key, value, generate_appearance: nil)
    validate_input(key, value)
    field = pdf_field(key)

    if generate_appearance.nil?
      field.setValue(value.to_s)
    else
      field.setValue(value.to_s, generate_appearance)
    end
  rescue StandardError => e
    raise "Unable to set field '#{key}': #{e.message}"
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
    # Check if the file exists; raise IOError if it doesn't
    raise IOError, "File <#{file_path}> is not found" unless File.exist?(file_path)

    begin
      field = pdf_field(key)
      widgets = field.getWidgets
      widget_dict = suppress_warnings { widgets.isEmpty ? field.getPdfObject : widgets.get(0).getPdfObject }
      orig_rect = widget_dict.getAsRectangle(ITEXT::PdfName.Rect)

      border_style = field.getWidgets.get(0).getBorderStyle
      border_width = border_style.nil? ? 0 : border_style.getWidth

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
      raise "Failed to set image for field '#{key}' (#{e.message})"
    end
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
    tmp_file = "#{Dir.tmpdir}/#{SecureRandom.uuid}"
    begin
      # Use strict_decode64 to ensure invalid Base64 data raises an error
      decoded_data = Base64.strict_decode64(base64_image_data)
      File.binwrite(tmp_file, decoded_data)
      set_image(key, tmp_file)
    rescue ArgumentError => e
      raise ArgumentError, "Invalid base64 data: #{e.message}"
    ensure
      FileUtils.rm_f(tmp_file)
    end
  end

  ##
  # Sets the values of multiple fields given a set of unique field names and values.
  #
  #   @param [Hash] fields the set of field names and values
  #   @param [NilClass|TrueClass|FalseClass] generate_appearance true to generate appearance, false to let the PDF viewer application generate form field appearance,  nil (default) to let iText decide what's appropriate
  #
  def set_fields(fields, generate_appearance: nil)
    fields.each { |key, value| set_field(key, value, generate_appearance: generate_appearance) }
  end

  ##
  # Renames a field given its unique field name and the new field name.
  #
  #   @param [String|Symbol] old_key the field name
  #   @param [String|Symbol] new_key the field name
  #
  def rename_field(old_key, new_key)
    old_key = old_key.to_s
    new_key = new_key.to_s

    raise "Field '#{old_key}' not found" unless @form_fields.containsKey(old_key)
    raise "Field name '#{new_key}' already exists" if @form_fields.containsKey(new_key)

    field = pdf_field(old_key)
    field.setFieldName(new_key)

    @form_fields.remove(old_key)
    @form_fields.put(new_key, field)
  rescue StandardError => e
    raise "Unable to rename field '#{old_key}' to '#{new_key}': #{e.message}"
  end

  ##
  # Removes a field from the document given its unique field name.
  #
  #   @param [String|Symbol] key the field name
  #
  def remove_field(key)
    if @form_fields.containsKey(key.to_s)
      @pdf_form.removeField(key.to_s)
      @form_fields.remove(key.to_s)
    else
      raise "Unknown key name `#{key}'"
    end
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
    tmp_file = "#{Dir.tmpdir}/#{SecureRandom.uuid}"
    save_as(tmp_file, flatten: flatten)
    FileUtils.mv tmp_file, @file_path
  end

  ##
  # Saves the filled out PDF document in a given path and flattens it if requested.
  #
  #   @param [String] file_path the name of the PDF file or file path
  #   @param [TrueClass|FalseClass] flatten true if PDF should be flattened, false otherwise
  #
  def save_as(file_path, flatten: false)
    if @file_path == file_path
      save(flatten: flatten)
    else
      File.open(file_path, 'wb') { |f| f.write(finalize(flatten: flatten)) && f.close }
    end
  rescue StandardError
    raise "Failed to save file '#{file_path}'"
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
  #   @param [TrueClass|FalseClass] flatten: true if PDF should be flattened, false otherwise
  #
  def finalize(flatten: false)
    @pdf_form.flattenFields if flatten
    close
    @byte_stream.toByteArray
  rescue StandardError
    raise 'Failed to finalize document'
  end

  def pdf_field(key)
    field = @form_fields.get(key.to_s)
    raise "Unknown key name `#{key}'" if field.nil?
    field
  end

  def validate_input(key, value)
    raise ArgumentError, 'Field name must be a string or symbol' unless key.is_a?(String) || key.is_a?(Symbol)
    raise ArgumentError, 'Field value cannot be nil' if value.nil?
  end

  def handle_pdf_open_error(err)
    raise "#{err.message} (Input file may be corrupt, incompatible, read-only, write-protected, encrypted, or may not have any form fields)" # rubocop:disable Layout/LineLength
  end
end
