require_relative 'support/pdf_test_base'

class PdfSaveTest < PdfTestBase
  def test_that_a_file_can_be_saved
    @pdf.save_as(@tmp)

    refute_nil FillablePDF.new(@tmp)
    @pdf = FillablePDF.new(@tmp)
    @pdf.save

    refute_nil FillablePDF.new(@tmp)
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
    assert_raises(FillablePDF::FieldNotFoundError) { reloaded_pdf.field(:first_name) }
    assert_equal 0, reloaded_pdf.num_fields
  ensure
    reloaded_pdf&.close
  end

  def test_save_preserves_modifications
    @pdf.set_field(:first_name, 'Saved Name')
    @pdf.save_as(@tmp)

    reloaded_pdf = FillablePDF.new(@tmp)

    assert_equal 'Saved Name', reloaded_pdf.field(:first_name)
  ensure
    reloaded_pdf&.close
  end

  def test_save_preserves_removed_fields
    @pdf.remove_field(:first_name)
    @pdf.save_as(@tmp)

    reloaded_pdf = FillablePDF.new(@tmp)

    refute_includes reloaded_pdf.names, :first_name
  ensure
    reloaded_pdf&.close
  end

  def test_save_preserves_renamed_fields
    tmp_file = Tempfile.new(['renamed', '.pdf'], 'test/files')
    tmp_path = tmp_file.path
    tmp_file.close

    pdf = FillablePDF.new(@original_pdf)
    pdf.rename_field(:first_name, :given_name)
    pdf.save_as(tmp_path)

    reloaded_pdf = FillablePDF.new(tmp_path)

    assert_includes reloaded_pdf.names, :given_name
    assert_equal 'Test', reloaded_pdf.field(:given_name)
  ensure
    reloaded_pdf&.close
    FileUtils.rm_f(tmp_path)
  end

  def test_flatten_removes_all_fields
    @pdf.save_as(@tmp, flatten: true)

    reloaded_pdf = FillablePDF.new(@tmp)

    assert_equal 0, reloaded_pdf.num_fields
    refute_predicate reloaded_pdf, :any_fields?
  ensure
    reloaded_pdf&.close
  end

  def test_save_without_flatten_preserves_fields
    tmp_file = Tempfile.new(['no-flatten', '.pdf'], 'test/files')
    tmp_path = tmp_file.path
    tmp_file.close

    initial_count = @pdf.num_fields
    @pdf.save_as(tmp_path, flatten: false)

    reloaded_pdf = FillablePDF.new(tmp_path)

    assert_equal initial_count, reloaded_pdf.num_fields
  ensure
    reloaded_pdf&.close
    FileUtils.rm_f(tmp_path)
  end
end
