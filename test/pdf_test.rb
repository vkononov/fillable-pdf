require 'test_helper'
require 'tempfile'

class PdfTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  def setup
    # Path to the original PDF
    @original_pdf = 'test/files/filled-out.pdf'

    # Create a temporary copy of the original PDF for testing
    @temp_pdf = Tempfile.new(['filled-out', '.pdf'], 'test/files')
    FileUtils.cp(@original_pdf, @temp_pdf.path)

    # Initialize FillablePDF with the temporary PDF
    @pdf = FillablePDF.new(@temp_pdf.path)

    # Temporary file path for saving modifications
    @tmp = Tempfile.new(['tmp', '.pdf'], 'test/files').path

    # Base64 encoded image data
    @base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
  end

  def teardown
    # Close the FillablePDF instance
    @pdf&.close

    # Delete the temporary PDF files
    @temp_pdf.close!
    FileUtils.rm_f(@tmp)
  end

  def test_that_it_has_a_version_number
    refute_nil FillablePDF::VERSION
  end

  def test_set_image_base64_with_tempfile
    Tempfile.create(['image', '.png']) do |_temp|
      # Use strict_encode64 to avoid newline characters
      image_data = Base64.strict_encode64(File.read('test/files/signature.png'))
      @pdf.set_image_base64(:signature, image_data)
      # Add assertions related to the image being set
      # Example:
      assert @pdf.set_image_base64(:signature, image_data)
    end
  end

  def test_that_a_file_is_loaded
    refute_nil @pdf
  end

  def test_that_an_error_is_thrown_for_non_existing_file
    err = assert_raises IOError do
      @pdf = FillablePDF.new 'test.pdf'
    end

    assert_match 'is not found', err.message
  end

  def test_that_file_has_editable_fields
    assert_predicate @pdf, :any_fields?
  end

  def test_that_file_has_a_positive_number_of_editable_fields
    assert_predicate @pdf.num_fields, :positive?
  end

  def test_that_hash_can_be_accessed
    assert_equal 12, @pdf.fields.length
  end

  def test_that_a_field_value_can_be_accessed_by_name
    assert_equal 'Test', @pdf.field(:first_name)
    assert_equal 'Test', @pdf.field(:last_name)
  end

  def test_that_a_field_type_can_be_accessed_by_name
    assert_equal FillablePDF::Field::TEXT, @pdf.field_type(:first_name)
    assert_equal FillablePDF::Field::BUTTON, @pdf.field_type(:football)
  end

  def test_that_a_field_value_can_be_modified
    @pdf.set_field(:first_name, 'Richard')

    assert_equal 'Richard', @pdf.field(:first_name)
  end

  def test_that_an_image_can_be_placed_in_signature_field
    assert @pdf.set_image(:signature, 'test/files/signature.png')
  end

  def test_that_a_base64_can_be_placed_in_photo_field
    assert @pdf.set_image_base64(:photo, @base64)
  end

  def test_that_an_asian_font_works
    @pdf.set_field(:first_name, '理查德')

    assert_equal '理查德', @pdf.field(:first_name)
  end

  def test_that_multiple_field_values_can_be_modified
    @pdf.set_fields({first_name: 'Richard', last_name: 'Rahl'})

    assert_equal 'Richard', @pdf.field(:first_name)
    assert_equal 'Rahl', @pdf.field(:last_name)
  end

  def test_that_a_checkbox_can_be_checked_and_unchecked
    @pdf.set_field(:nascar, 'Yes')

    assert_equal 'Yes', @pdf.field(:nascar)
    @pdf.set_field(:newsletter, 'Off')

    assert_equal 'Off', @pdf.field(:newsletter)
  end

  def test_that_a_radio_button_can_be_checked_and_unchecked
    @pdf.set_field(:language, 'ruby')

    assert_equal 'ruby', @pdf.field(:language)
    @pdf.set_field(:language, 'Off')

    assert_equal 'Off', @pdf.field(:language)
  end

  def test_that_a_field_can_be_renamed
    @pdf.rename_field(:last_name, :surname)
    @pdf.save_as(@tmp)
    @pdf = FillablePDF.new(@tmp)
    err = assert_raises RuntimeError do
      @pdf.field(:last_name)
    end

    assert_match 'Unknown key name', err.message
    assert_equal 'Test', @pdf.field(:surname)
  end

  def test_that_a_field_can_be_removed
    assert @pdf.remove_field(:first_name)
    err = assert_raises RuntimeError do
      @pdf.field(:first_name)
    end

    assert_match 'Unknown key name', err.message
  end

  def test_that_field_names_can_be_accessed
    assert_includes @pdf.names, :first_name
  end

  def test_that_field_values_can_be_accessed
    assert_includes @pdf.values, 'Test'
  end

  def test_that_a_file_can_be_saved
    @pdf.save_as(@tmp)

    refute_nil FillablePDF.new(@tmp)
    @pdf = FillablePDF.new(@tmp)
    @pdf.save

    refute_nil FillablePDF.new(@tmp)
  end

  def test_that_a_file_can_be_closed
    assert @pdf.close
  end

  def test_set_field_with_invalid_key
    err = assert_raises RuntimeError do
      @pdf.set_field(:invalid_key, 'Value')
    end
    assert_match 'Unknown key name', err.message
  end

  def test_field_with_invalid_key
    err = assert_raises RuntimeError do
      @pdf.field(:invalid_key)
    end
    assert_match 'Unknown key name', err.message
  end

  def test_field_type_with_invalid_key
    err = assert_raises RuntimeError do
      @pdf.field_type(:invalid_key)
    end
    assert_match 'Unknown key name', err.message
  end

  def test_set_image_with_invalid_path
    err = assert_raises IOError do
      @pdf.set_image(:signature, 'nonexistent.png')
    end
    assert_match 'is not found', err.message
  end

  def test_set_image_base64_with_invalid_data
    invalid_base64 = 'invalid_base64_data'
    err = assert_raises ArgumentError do
      @pdf.set_image_base64(:photo, invalid_base64)
    end
    assert_match 'Invalid base64', err.message # Match exact casing
  end

  def test_save_as_with_same_path
    assert_silent do
      @pdf.save_as(@pdf.instance_variable_get(:@file_path))
    end
  end

  def test_save_with_flattening
    @pdf.set_field(:first_name, 'Flattened Name')
    @pdf.save_as(@tmp, flatten: true)
    reloaded_pdf = FillablePDF.new(@tmp)
    assert_raises(RuntimeError) { reloaded_pdf.field(:first_name) }
    assert_equal 0, reloaded_pdf.num_fields
  ensure
    reloaded_pdf&.close
  end

  def test_open_encrypted_pdf
    encrypted_pdf_path = 'test/files/encrypted.pdf'
    err = assert_raises StandardError do
      FillablePDF.new(encrypted_pdf_path)
    end
    assert_match 'file may be corrupt, incompatible, read-only, write-protected, encrypted', err.message
  end

  def test_open_signed_and_certified_pdf
    encrypted_pdf_path = 'test/files/signed-and-certified.pdf'
    # Assuming you have an encrypted PDF for testing
    pdf = FillablePDF.new(encrypted_pdf_path)

    assert_predicate pdf, :any_fields?
    pdf.close
  end

  def test_rename_field_to_existing_name
    # First, rename :last_name to :surname to create the :surname field
    @pdf.rename_field(:last_name, :surname)

    # Now, attempt to rename :first_name to :surname, which should raise an error
    err = assert_raises RuntimeError do
      @pdf.rename_field(:first_name, :surname)
    end
    assert_match "Field name 'surname' already exists", err.message
  end

  def test_remove_nonexistent_field
    err = assert_raises RuntimeError do
      @pdf.remove_field(:nonexistent_field)
    end
    assert_match 'Unknown key name', err.message # Use exact case
  end
end
