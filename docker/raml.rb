require 'fileutils'
require 'open-uri'
require 'yaml'

module DescriptionParser

  def description
    if (not @description)
      @description = (@obj.has_key?('description') ? @obj['description'] : '')
      @extended_attributes = _extract_attributes(@description.dup)
    end
    @description
  end

  def clean_description
    if (not @clean_description)
      desc = @description.dup
      while (desc.sub!(/\s*\[.*?\]\s*$/, ''))
      end
      desc += " [Since:#{since}]"
      @clean_description = desc
    end
    @clean_description
  end

  def value_of(key)
    description if not @extended_attributes
    key = key.downcase
    return @extended_attributes.has_key?(key) ? @extended_attributes[key] : ''
  end

  def extended_attributes
    if (not @extended_attributes)
      # The "description" method populates the "extended_attributes" attr
      description
    end
    @extended_attributes
  end

  private

  def _extract_attributes(desc)
    attributes = {}
    while (desc.sub!(/\[([^:]+):([^\]]+)\]\s*$/, ''))
      attributes[$1.downcase] = $2
    end
    return attributes
  end

  attr_writer :description, :extended_attributes

end

class Resource
  include DescriptionParser

  def initialize(dict, uri='', inheritedSince='0.0')
    @uri = uri
    @obj = dict
    localSince = value_of('since')
    @since = localSince.greaterThanVersion(inheritedSince) \
           ? localSince \
           : inheritedSince
  end

  def resources
    @obj.keys.grep(/^\//).map {|e| Resource.new(@obj[e], File.join(@uri, e), @since)}
  end

  def all_resources
    list = []
    resources.each do |res|
      list.push(res)
      list += res.all_resources
    end
    list
  end

  def actions
    @obj.keys.find_all{|k| k =~ /^(get|put|post|delete)$/}.map{|e| Action.new(@obj[e], e)}
  end

  attr_reader :uri, :since

end

class Action
  include DescriptionParser

  def initialize(dict, action)
    @action = action
    @obj = dict
  end

  def type
    return @action
  end

end

class RAML < Resource

  def initialize(infile)
    inputdir = File.dirname(infile)
    input = open(infile, 'r:UTF-8') do |f|
      inlined_raml = ''
      f.readlines.each do |line|
        if (line !~ /^\s*#/ and line =~ /\!include\s+(.*)/)
          incfile = $1
          incfile = File.join(inputdir, incfile) unless File.exists?(incfile)
          inc = open(incfile).read
          inlined_raml += inc
        else
          inlined_raml += line
        end
      end
      inlined_raml
    end

    super(YAML.load(input))
  end

  def filternodes(version)
    return _filternodes(@obj, version)
  end

  def dump
    raml = @obj.to_yaml
    raml.sub!(/^---/, "#%RAML 0.8");
    return raml
  end

  private

  def _filternodes(node, version)
    seen_versions = {}
    return seen_versions unless node.is_a?(Hash)

    node.keys.each do |key|
      next unless node[key].is_a?(Hash)

      if (node[key].has_key?('description') and
          node[key]['description'].is_a?(String))
        since = node[key]['description'].value_of('Since')
        if (version and version.length > 0 and since.greaterThanVersion(version))
          node.delete(key)
        elsif (since.length > 0)
          seen_versions[since] = true
        end
      end
      subversions = _filternodes(node[key], version) if node.has_key?(key)
      seen_versions.merge!(subversions) if subversions
    end
    return seen_versions
  end

end

class String
  # Extract the specified value from the description where the key/value
  # combintion looks like this: "[Key:Value]"
  # For example: "[Since:1.2]" => "1.2"
  def value_of(pattern)
    if (self =~ /\[#{pattern}:(.*?)\]/i)
      return $1;
    end
    return ''
  end

  # Compare a given version string to current version
  # Will *only* work on strings which are in dotted notation.
  # Examples: "1.10", "3.14.15.9"
  def greaterThanVersion(version)
    Gem::Version.new(self.dup) > Gem::Version.new(version.dup)
  end
end
