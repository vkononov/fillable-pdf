require_relative 'support/pdf_test_base'

class PdfAtomicSaveTest < PdfTestBase
  def test_finalization_failure_keeps_destination_and_removes_temporary_file
    File.binwrite(@tmp, 'existing contents')
    before = Dir.glob(File.join(File.dirname(@tmp), '.fillable-pdf-*'))
    @pdf.define_singleton_method(:finalize) { |**| raise 'simulated finalization failure' }

    assert_raises(FillablePDF::FileOperationError) { @pdf.save_as(@tmp) }
    assert_equal 'existing contents', File.binread(@tmp)
    assert_equal before, Dir.glob(File.join(File.dirname(@tmp), '.fillable-pdf-*'))
  end

  def test_save_as_through_symlink_keeps_link_and_writes_complete_pdf
    link = "#{@tmp}.link"
    File.symlink(File.expand_path(@temp_pdf.path), link)
    @pdf.set_field(:first_name, 'Alias')
    @pdf.save_as(link)

    assert File.symlink?(link)
    reloaded = FillablePDF.new(link)

    assert_equal 'Alias', reloaded.field(:first_name)
  ensure
    reloaded&.close
    FileUtils.rm_f(link)
  end

  def test_save_as_bang_rejects_hard_link_to_source_before_closing_document
    link = "#{@tmp}.hardlink"
    File.link(@temp_pdf.path, link)
    original = File.binread(@temp_pdf.path)

    assert_raises(FillablePDF::InvalidArgumentError) { @pdf.save_as!(link) }
    refute_predicate @pdf, :closed?
    assert_equal original, File.binread(link)
  ensure
    FileUtils.rm_f(link)
  end
end
