require_relative 'support/pdf_test_base'

class PdfStateTest < PdfTestBase
  def test_num_fields_after_removing_field
    initial_count = @pdf.num_fields
    @pdf.remove_field(:first_name)

    assert_equal initial_count - 1, @pdf.num_fields
  end

  def test_num_fields_after_removing_multiple_fields
    initial_count = @pdf.num_fields
    @pdf.remove_field(:first_name)
    @pdf.remove_field(:last_name)

    assert_equal initial_count - 2, @pdf.num_fields
  end

  def test_any_fields_after_removing_all_fields
    @pdf.names.each { |name| @pdf.remove_field(name) }

    refute_predicate @pdf, :any_fields?
    assert_equal 0, @pdf.num_fields
  end

  def test_fields_hash_after_rename
    @pdf.rename_field(:first_name, :given_name)
    fields = @pdf.fields

    assert_includes fields.keys, :given_name
    refute_includes fields.keys, :first_name
  end

  def test_fields_hash_after_remove
    @pdf.remove_field(:first_name)
    fields = @pdf.fields

    refute_includes fields.keys, :first_name
  end

  def test_names_after_rename
    @pdf.rename_field(:first_name, :given_name)
    names = @pdf.names

    assert_includes names, :given_name
    refute_includes names, :first_name
  end

  def test_values_reflect_current_state
    @pdf.set_field(:first_name, 'Updated')

    assert_includes @pdf.values, 'Updated'
  end
end
