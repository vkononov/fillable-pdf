require_relative 'support/pdf_test_base'

class PdfBasicTest < PdfTestBase
  def test_that_it_has_a_version_number
    refute_nil FillablePDF::VERSION
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

  def test_that_field_names_can_be_accessed
    assert_includes @pdf.names, :first_name
  end

  def test_that_field_values_can_be_accessed
    assert_includes @pdf.values, 'Test'
  end

  def test_that_a_file_can_be_closed
    assert @pdf.close
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
    pdf = FillablePDF.new(encrypted_pdf_path)

    assert_predicate pdf, :any_fields?
    pdf.close
  end
end
