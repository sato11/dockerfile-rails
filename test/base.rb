require "minitest/autorun"

require "active_support"
require "active_support/core_ext/string/inflections"

class TestBase < Minitest::Test
  make_my_diffs_pretty! 

  class << self
    attr_accessor :rails_options, :generate_options
  end

  def app_setup
  end

  def setup
    @capture = ENV['TEST_CAPTURE']

    @appname = self.class.name.underscore
    @results = File.expand_path(@appname.sub('test_', ''), 'test/results')
    FileUtils.mkdir_p @results if @capture

    Dir.chdir 'test/tmp'

    system "rails new #{self.class.rails_options} #{@appname}"

    Dir.chdir @appname

    app_setup

    system 'bundle config disable_local_branch_check true'
    system "bundle config set --local local.dockerfile-rails #{File.expand_path('..', __dir__)}"
    system "bundle add dockerfile-rails --git https://github.com/rubys/dockerfile-rails.git --group development"

    ENV['RAILS_ENV'] = 'test'
    system "bin/rails generate dockerfile #{self.class.generate_options}"
  end

  def check_dockerfile
    results = IO.read('Dockerfile')
      .gsub(/(^ARG\s+\w+\s*=).*/, '\1xxx')

    IO.write("#{@results}/Dockerfile", results) if @capture

    expected = IO.read("#{@results}/Dockerfile")
      .gsub(/(^ARG\s+\w+\s*=).*/, '\1xxx')

    assert_equal expected, results
  end

  def check_compose
    results = IO.read('docker-compose.yml')

    IO.write("#{@results}/docker-compose.yml", results) if @capture

    expected = IO.read("#{@results}/docker-compose.yml")
    
    assert_equal expected, results
  end

  def check_entrypoint
    results = IO.read('bin/docker-entrypoint')

    IO.write("#{@results}/docker-entrypoint", results) if @capture

    expected = IO.read("#{@results}/docker-entrypoint")
    
    assert_equal expected, results
  end

  def teardown
    Dir.chdir '..'
    FileUtils.rm_rf @appname
    Dir.chdir '../..'
  end
end