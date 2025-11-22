require_relative 'support/pdf_test_base'

class PdfFieldOperationsTest < PdfTestBase
  def test_that_a_field_value_can_be_modified
    @pdf.set_field(:first_name, 'Richard')

    assert_equal 'Richard', @pdf.field(:first_name)
  end

  def test_that_multiple_field_values_can_be_modified
    @pdf.set_fields({first_name: 'Richard', last_name: 'Rahl'})

    assert_equal 'Richard', @pdf.field(:first_name)
    assert_equal 'Rahl', @pdf.field(:last_name)
  end

  def test_set_field_with_generate_appearance_true
    @pdf.set_field(:first_name, 'Appearance Test', generate_appearance: true)

    assert_equal 'Appearance Test', @pdf.field(:first_name)
  end

  def test_set_field_with_generate_appearance_false
    @pdf.set_field(:first_name, 'No Appearance', generate_appearance: false)

    assert_equal 'No Appearance', @pdf.field(:first_name)
  end

  def test_set_fields_with_generate_appearance_true
    @pdf.set_fields({first_name: 'John', last_name: 'Doe'}, generate_appearance: true)

    assert_equal 'John', @pdf.field(:first_name)
    assert_equal 'Doe', @pdf.field(:last_name)
  end

  def test_set_fields_with_generate_appearance_false
    @pdf.set_fields({first_name: 'Jane', last_name: 'Smith'}, generate_appearance: false)

    assert_equal 'Jane', @pdf.field(:first_name)
    assert_equal 'Smith', @pdf.field(:last_name)
  end

  def test_that_a_field_can_be_renamed
    @pdf.rename_field(:last_name, :surname)
    @pdf.save_as(@tmp)
    @pdf = FillablePDF.new(@tmp)
    err = assert_raises FillablePDF::FieldNotFoundError do
      @pdf.field(:last_name)
    end

    assert_match 'Unknown key name', err.message
    assert_equal 'Test', @pdf.field(:surname)
  end

  def test_rename_field_to_existing_name
    @pdf.rename_field(:last_name, :surname)

    err = assert_raises FillablePDF::InvalidArgumentError do
      @pdf.rename_field(:first_name, :surname)
    end
    assert_match 'already exists', err.message
  end

  def test_that_a_field_can_be_removed
    @pdf.remove_field(:first_name)
    err = assert_raises FillablePDF::FieldNotFoundError do
      @pdf.field(:first_name)
    end

    assert_match 'Unknown key name', err.message
  end

  def test_remove_nonexistent_field
    err = assert_raises FillablePDF::FieldNotFoundError do
      @pdf.remove_field(:nonexistent_field)
    end
    assert_match 'Unknown key name', err.message
  end

  def test_multiple_sequential_modifications
    @pdf.set_field(:first_name, 'First')

    assert_equal 'First', @pdf.field(:first_name)

    @pdf.set_field(:first_name, 'Second')

    assert_equal 'Second', @pdf.field(:first_name)

    @pdf.set_field(:first_name, 'Third')

    assert_equal 'Third', @pdf.field(:first_name)
  end

  def test_modify_field_after_rename
    @pdf.rename_field(:first_name, :given_name)
    @pdf.set_field(:given_name, 'Renamed Value')

    assert_equal 'Renamed Value', @pdf.field(:given_name)
  end
end
