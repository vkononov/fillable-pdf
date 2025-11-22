require_relative 'fillable-pdf/itext'
require_relative 'fillable-pdf/suppress_warnings'
require_relative 'fillable-pdf/field'
require_relative 'fillable-pdf/errors'
require 'base64'
require 'securerandom'
require 'tmpdir'

class FillablePDF # rubocop:disable Metrics/ClassLength
  include SuppressWarnings

  ##
  # Opens a given fillable-pdf PDF file and prepares it for modification.
  #
  #   @param [String|Symbol] file_path the name of the PDF file or file path
  #   @raise [FileOperationError] if the file is not found or cannot be opened
  #
  def initialize(file_path) # rubocop:disable Metrics/MethodLength
    raise FileOperationError, "File <#{file_path}> is not found" unless File.exist?(file_path)
    @file_path = file_path
    @closed = false
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
  #   @return [Boolean] true if form has fields, false otherwise
  #
  def any_fields?
    field_count.positive?
  end

  ##
  # Returns the total number of fillable form fields.
  #
  #   @return [Integer] the number of fields
  #
  def field_count
    @form_fields.size
  end

  ##
  # @deprecated Use {#field_count} instead
  def num_fields
    warn '[DEPRECATION] `num_fields` is deprecated. Use `field_count` instead.'
    field_count
  end

  ##
  # Retrieves the value of a field given its unique field name.
  #
  #   @param [String|Symbol] key the field name
  #   @return [String] the value of the field
  #   @raise [FieldNotFoundError] if the field does not exist
  #
  def field(key)
    pdf_field(key).getValueAsString
  rescue NoMethodError
    raise FieldNotFoundError, "Unknown key name `#{key}'"
  end

  ##
  # Retrieves the string type of a field given its unique field name.
  #
  #   @param [String|Symbol] key the field name
  #   @return [String, nil] the type of the field (e.g., '/Btn', '/Tx', '/Ch', '/Sig')
  #   @raise [FieldNotFoundError] if the field does not exist
  #
  def field_type(key)
    pdf_field(key).getFormType&.toString
  end

  ##
  # Retrieves a hash of all fields and their values.
  #
  #   @return [Hash{Symbol => String}] hash of field keys (as symbols) and values
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
  #   @param [Boolean, nil] generate_appearance true to generate appearance, false to let the PDF viewer application generate form field appearance, nil (default) to let iText decide what's appropriate
  #   @return [self] returns self for method chaining
  #   @raise [InvalidArgumentError] if key or value are invalid
  #   @raise [FieldNotFoundError] if the field does not exist
  #
  def set_field(key, value, generate_appearance: nil)
    ensure_document_open
    validate_input(key, value)
    field = pdf_field(key)

    if generate_appearance.nil?
      field.setValue(value.to_s)
    else
      field.setValue(value.to_s, generate_appearance)
    end

    self
  end

  ##
  # Sets an image within the bounds of the given form field. It doesn't matter
  # what type of form field it is (signature, image, etc). The image will be scaled
  # to fill the available space while preserving its aspect ratio. All previous
  # content will be removed, which means you cannot have both text and image.
  #
  #   @param [String|Symbol] key the field name
  #   @param [String|Symbol] file_path the name of the image file or image path
  #   @return [self] returns self for method chaining
  #   @raise [FileOperationError] if the image file is not found
  #   @raise [FieldNotFoundError] if the field does not exist
  #
  def set_image(key, file_path) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    ensure_document_open
    raise FileOperationError, "File <#{file_path}> is not found" unless File.exist?(file_path)

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
      raise FileOperationError, "Failed to set image for field '#{key}': #{e.message}"
    end

    self
  end

  ##
  # Sets an image within the bounds of the given form field. It doesn't matter
  # what type of form field it is (signature, image, etc). The image will be scaled
  # to fill the available space while preserving its aspect ratio. All previous
  # content will be removed, which means you cannot have both text and image.
  #
  #   @param [String|Symbol] key the field name
  #   @param [String] base64_image_data base64 encoded image data
  #   @return [self] returns self for method chaining
  #   @raise [InvalidArgumentError] if the base64 data is invalid
  #   @raise [FieldNotFoundError] if the field does not exist
  #
  def set_image_base64(key, base64_image_data)
    ensure_document_open
    tmp_file = "#{Dir.tmpdir}/#{SecureRandom.uuid}"
    begin
      decoded_data = Base64.strict_decode64(base64_image_data)
      File.binwrite(tmp_file, decoded_data)
      set_image(key, tmp_file)
    rescue ArgumentError => e
      raise InvalidArgumentError, "Invalid base64 data: #{e.message}"
    ensure
      FileUtils.rm_f(tmp_file)
    end

    self
  end

  ##
  # Sets the values of multiple fields given a set of unique field names and values.
  #
  #   @param [Hash{String, Symbol => String}] fields the set of field names and values
  #   @param [Boolean, nil] generate_appearance true to generate appearance, false to let the PDF viewer application generate form field appearance,  nil (default) to let iText decide what's appropriate
  #   @return [self] returns self for method chaining
  #   @raise [InvalidArgumentError] if any key or value is invalid
  #   @raise [FieldNotFoundError] if any field does not exist
  #
  def set_fields(fields, generate_appearance: nil)
    ensure_document_open
    fields.each { |key, value| set_field(key, value, generate_appearance: generate_appearance) }
    self
  end

  ##
  # Renames a field given its unique field name and the new field name.
  #
  #   @param [String|Symbol] old_key the current field name
  #   @param [String|Symbol] new_key the new field name
  #   @return [self] returns self for method chaining
  #   @raise [FieldNotFoundError] if the field does not exist
  #   @raise [InvalidArgumentError] if the new field name already exists
  #
  def rename_field(old_key, new_key) # rubocop:disable Metrics/MethodLength
    ensure_document_open
    validate_field_name(old_key)
    validate_field_name(new_key)

    old_key = old_key.to_s
    new_key = new_key.to_s

    raise FieldNotFoundError, "Field `#{old_key}` not found" unless @form_fields.containsKey(old_key)
    raise InvalidArgumentError, "Field name `#{new_key}` already exists" if @form_fields.containsKey(new_key)

    field = pdf_field(old_key)
    field.setFieldName(new_key)

    @form_fields.remove(old_key)
    @form_fields.put(new_key, field)

    self
  rescue FieldNotFoundError, InvalidArgumentError
    raise
  rescue StandardError => e
    raise FileOperationError, "Unable to rename field `#{old_key}` to `#{new_key}`: #{e.message}"
  end

  ##
  # Removes a field from the document given its unique field name.
  #
  #   @param [String|Symbol] key the field name
  #   @return [self] returns self for method chaining
  #   @raise [FieldNotFoundError] if the field does not exist
  #
  def remove_field(key)
    ensure_document_open
    validate_field_name(key)
    raise FieldNotFoundError, "Unknown key name `#{key}'" unless @form_fields.containsKey(key.to_s)

    @pdf_form.removeField(key.to_s)
    @form_fields.remove(key.to_s)

    self
  end

  ##
  # Returns a list of all field keys used in the document.
  #
  #   @return [Array<Symbol>] array of field names as symbols
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
  #   @return [Array<String>] array of field values
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
  #   @param [Boolean] flatten true if PDF should be flattened, false otherwise
  #   @return [self] returns self for method chaining
  #   @raise [FileOperationError] if the save operation fails
  #
  def save(flatten: false)
    ensure_document_open
    tmp_file = "#{Dir.tmpdir}/#{SecureRandom.uuid}"
    save_as(tmp_file, flatten: flatten)
    FileUtils.mv tmp_file, @file_path
    self
  end

  ##
  # Saves the filled out PDF document in a given path and flattens it if requested.
  # If the path matches the current file path, it will call save() instead.
  #
  #   @param [String] file_path the name of the PDF file or file path
  #   @param [Boolean] flatten true if PDF should be flattened, false otherwise
  #   @return [self] returns self for method chaining
  #   @raise [FileOperationError] if the save operation fails
  #
  def save_as(file_path, flatten: false)
    ensure_document_open
    if @file_path == file_path
      save(flatten: flatten)
      return self
    end

    File.open(file_path, 'wb') { |f| f.write(finalize(flatten: flatten)) && f.close }
    self
  rescue StandardError => e
    raise FileOperationError, "Failed to save file `#{file_path}`: #{e.message}"
  end

  ##
  # Saves the filled out PDF document in a given path and flattens it if requested.
  # Raises an error if the path matches the current file path (use save() instead).
  #
  #   @param [String] file_path the name of the PDF file or file path
  #   @param [Boolean] flatten true if PDF should be flattened, false otherwise
  #   @return [self] returns self for method chaining
  #   @raise [InvalidArgumentError] if file_path matches the current file path
  #   @raise [FileOperationError] if the save operation fails
  #
  def save_as!(file_path, flatten: false)
    ensure_document_open
    raise InvalidArgumentError, 'Cannot save_as! to the same file path. Use save() instead.' if @file_path == file_path

    File.open(file_path, 'wb') { |f| f.write(finalize(flatten: flatten)) && f.close }
    self
  rescue InvalidArgumentError
    raise
  rescue StandardError => e
    raise FileOperationError, "Failed to save file `#{file_path}`: #{e.message}"
  end

  ##
  # Closes the PDF document discarding all unsaved changes.
  #
  # @return [Boolean] true if document is closed
  #
  def close # rubocop:disable Naming/PredicateMethod
    return true if closed?

    @pdf_doc.close
    @closed = true
    true
  end

  ##
  # Checks if the PDF document is closed.
  #
  # @return [Boolean] true if document is closed, false otherwise
  #
  def closed?
    @closed ||= false
  end

  private

  ##
  # Writes the contents of the modified fields to the previously opened PDF file.
  #
  #   @param [Boolean] flatten true if PDF should be flattened, false otherwise
  #   @return [Java::byte[]] byte array of the PDF document
  #
  def finalize(flatten: false)
    @pdf_form.flattenFields if flatten
    close
    @byte_stream.toByteArray
  rescue StandardError => e
    raise FileOperationError, "Failed to finalize document: #{e.message}"
  end

  def pdf_field(key)
    field = @form_fields.get(key.to_s)
    raise FieldNotFoundError, "Unknown key name `#{key}'" if field.nil?
    field
  end

  def validate_input(key, value)
    validate_field_name(key)
    raise InvalidArgumentError, 'Field value cannot be nil' if value.nil?
  end

  def validate_field_name(key)
    raise InvalidArgumentError, 'Field name must be a string or symbol' unless key.is_a?(String) || key.is_a?(Symbol)
  end

  def ensure_document_open
    raise FileOperationError, 'Cannot perform operation on a closed PDF document' if closed?
  end

  def handle_pdf_open_error(err)
    raise FileOperationError, "#{err.message} (Input file may be corrupt, incompatible, read-only, write-protected, encrypted, or may not have any form fields)" # rubocop:disable Layout/LineLength
  end
end
