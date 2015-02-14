#!/usr/bin/env ruby

require 'fileutils'
require 'open-uri'
require 'yaml'

$DEBUG = false
$VERSION = ''

class String
  # Extract the specified value from the description where the key/value
  # combintion looks like this: "[Key:Value]"
  # For example: "[Since:1.2]" => "1.2"
  def valueOf(pattern)
    if (self =~ /\[#{pattern}:(.*?)\]/)
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

def log(msg)
  return unless $DEBUG;
  STDERR.puts(msg)
end

def filternodes(node, version)
  seen_versions = {}
  return seen_versions unless node.is_a?(Hash)

  node.keys.each do |key|
    next unless node[key].is_a?(Hash)
    
    if (node[key].has_key?('description') and
        node[key]['description'].is_a?(String))
      since = node[key]['description'].valueOf('Since')
      if (version and version.length > 0 and since.greaterThanVersion(version))
        node.delete(key)
      elsif (since.length > 0)
        seen_versions[since] = true
      end
    end
    subversions = filternodes(node[key], version) if node.has_key?(key)
    seen_versions.merge!(subversions) if subversions
  end
  return seen_versions
end

#
# MAIN
#

inputdir = ARGV.shift
outputdir = ARGV.shift
if (not inputdir or not outputdir or not File.directory?(inputdir))
  abort "usage: #{$0} <raml-dir> <output-dir>"
end

# Make sure output directory is empty
if (Dir.exists?(outputdir))
  abort "Output directory not empty: #{outputdir}" \
    unless Dir["#{outputdir}/*"].empty?
else
  log "Creating directory: #{outputdir}"
  Dir.mkdir(outputdir) or abort "Failed to create directory: #{outputdir}"
end

versions = [ '' ]
while (version = versions.shift)
  seen_versions = {}
  Dir[File.join(inputdir, "*.raml")].each do |inputfile|
    log "Processing file: #{inputfile}, version: #{version}" \
      if version.length > 0

    # Inline "!include" sections
    input = open(inputfile, 'r:UTF-8') do |f|
      inlined_raml = ''
      f.readlines.each do |line|
        if (line =~ /\!include\s+(.*)/)
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

    dict = YAML.load(input)
    v = filternodes(dict, version)
    seen_versions.merge!(v)

    if (version.length > 0)
      # Generate version-specific RAML file
      outversdir = File.join(outputdir, version)
      Dir.mkdir(outversdir) unless Dir.exists?(outversdir)

      outvers = File.join(outversdir, File.basename(inputfile))
      puts "Generating file: #{outvers}"
      File.open(outvers, 'w') do |f|
        raml = dict.to_yaml
        raml.sub!(/^---/, "#%RAML 0.8");
        f.write raml
      end
    end
  end

  if (version.length < 1)
    # First run -- populate versions list with seen versions
    versions = seen_versions.keys.sort
    puts "Generating RAMLs for versions: #{versions}"
  end
end
