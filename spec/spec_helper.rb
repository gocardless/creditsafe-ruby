# frozen_string_literal: true
require "webmock/rspec"
require "nokogiri"
require "rspec/its"
require "compare-xml"

def load_fixture(name)
  File.read(File.join(File.dirname(__FILE__), "fixtures", name))
end

def load_xml_fixture(name)
  Nokogiri::XML(File.open(File.join(File.dirname(__FILE__), "fixtures", name)))
end
