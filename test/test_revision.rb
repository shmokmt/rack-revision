require 'test/unit'
require 'rack/test'
require 'rack/revision'
require 'fileutils'

class TestRevision < Test::Unit::TestCase
  include Rack::Test::Methods

  def default_app
    lambda do |env|
      headers = {'Content-Type' => "text/html"}
      [200, headers, ["OK"]]
    end
  end

  def app
    @app ||= Rack::Revision.new(default_app)
  end

  def app_url
    "http://foobar.com/"
  end

  attr_writer :app

  def setup
    FileUtils.mkdir('./test/tmp')
  end

  def teardown
    FileUtils.rm_rf('./test/tmp')
  end

  def test_revision_request
    self.app.reset_revision
    get app_url

    assert last_response.ok?
  end

  def test_presence
    self.app.reset_revision
    get app_url

    assert_not_nil last_response.headers['X-REVISION']
    assert_not_nil last_response.headers['X-Revision']
  end

  def test_blank
    self.app = Rack::Revision.new(default_app, :header => false)
    self.app.reset_revision
    get app_url

    assert_nil last_response.headers['X-REVISION']
    assert_nil last_response.headers['X-Revision']
  end

  def test_default_value
    self.app.reset_revision
    get app_url

    assert_equal "UNDEFINED", last_response.headers['X-Revision']
  end

  def test_custom_value
    self.app = Rack::Revision.new(default_app, :default => "FOOBAR")
    self.app.reset_revision

    get app_url
    assert_equal "FOOBAR", last_response.headers['X-Revision']
  end

  def test_custom_header
    self.app = Rack::Revision.new(default_app, :header => "FOOBAR")
    self.app.reset_revision

    get app_url
    assert_not_nil last_response.headers['FOOBAR']
  end

  def test_default_filename
    File.open('./test/tmp/REVISION', 'w') { |f| f.write('qwe123') }

    self.app = Rack::Revision.new(default_app, :filename => './test/tmp/REVISION')
    self.app.reset_revision

    get app_url
    assert_equal 'qwe123', last_response.headers['X-Revision']
  end
end
