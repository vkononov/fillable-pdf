require 'test_helper'

class PdfTest < Minitest::Test
  def setup
    @pdf = FillablePDF.new 'test/files/filled-out.pdf'
    @tmp = 'test/files/tmp.pdf'
  end

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
    assert @pdf.any_fields?
  end

  def test_that_file_has_a_positive_number_of_editable_fields
    assert @pdf.num_fields.positive?
  end

  def test_that_hash_can_be_accessed
    assert_equal 14, @pdf.fields.length
  end

  def test_that_a_field_value_can_be_accessed_by_name
    assert_equal 'Test', @pdf.field(:first_name)
    assert_equal 'Test', @pdf.field(:last_name)
  end

  def test_that_a_field_type_can_be_accessed_by_name
    assert_equal Field::TEXT, @pdf.field_type(:first_name)
    assert_equal Field::BUTTON, @pdf.field_type(:football)
  end

  def test_that_a_field_value_can_be_modified
    @pdf.set_field(:first_name, 'Richard')
    assert_equal 'Richard', @pdf.field(:first_name)
  end

  def test_that_an_asian_font_works
    @pdf.set_field(:first_name, '理查德')
    assert_equal '理查德', @pdf.field(:first_name)
  end

  def test_that_multiple_field_values_can_be_modified
    @pdf.set_fields(first_name: 'Richard', last_name: 'Rahl')
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
    3.times { |i| assert_equal 'ruby', @pdf.field("language.#{i}".gsub('.0', '')) }
    @pdf.set_field(:language, 'Off')
    3.times { |i| assert_equal 'Off', @pdf.field("language.#{i}".gsub('.0', '')) }
  end

  def test_that_a_field_can_be_renamed
    @pdf.rename_field(:last_name, :surname)
    @pdf.save_as(@tmp)
    @pdf = FillablePDF.new(@tmp)
    err = assert_raises RuntimeError do
      @pdf.field(:last_name)
    end
    assert_match 'unknown key name', err.message
    assert_equal 'Test', @pdf.field(:surname)
  end

  def test_that_a_field_can_be_removed
    @pdf.remove_field(:first_name)
    err = assert_raises RuntimeError do
      @pdf.field(:first_name)
    end
    assert_match 'unknown key name', err.message
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
end
