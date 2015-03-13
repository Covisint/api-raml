#!/usr/bin/env ruby

require 'fileutils'
require 'yaml'
require File.join(File.dirname($0), 'raml')

$DEBUG = false
$VERSION = ''

def log(msg)
  return unless $DEBUG;
  STDERR.puts(msg)
end

inputdir = ARGV.shift
outputbase = ARGV.shift
manifest = ARGV.shift
if (not inputdir or not outputbase or
    not (File.directory?(inputdir) or inputdir =~ /\.raml$/))
  abort "usage: #{$0} <raml-dir> <output-dir> [<release-manifest>]"
end

# Make sure output directories are empty
outputdir = File.join(outputbase, 'versions')
if (Dir.exists?(outputdir))
  abort "Output directory not empty: #{outputdir.sub(/^\/raml\//, '')}" \
    unless Dir["#{outputdir}/*"].empty?
else
  log "Creating directory: #{outputdir}"
  FileUtils.mkdir_p(outputdir) or abort "Failed to create directory: #{outputdir}"
end

# Get a list of all available "Since" values
versions = {}
ramlfiles = File.directory?(inputdir) ? Dir[File.join(inputdir, '*.raml')] : [ inputdir ]
ramlfiles.each do |ramlfile|
  raml = RAML.new(ramlfile)
  raml.walknodes do |node, keys|
    next unless node.has_key?('description')
    next unless node['description'].is_a?(String)
    since = node['description'].value_of('Since')
    versions[since] = true if since.length > 0
  end
end
abort 'No "Since:" tags found in any of the RAML files' if versions.empty?

methods = %( get put post delete )
[ 'public', 'private' ].each do |visibility|
  visibility_filter = (visibility == 'public' ? 'public' : nil)

  puts "\nGenerating #{visibility} RAMLs for versions: #{versions.keys.sort}"
  versions.keys.sort.each do |version|
    ramlfiles.each do |inputfile|
      log "Processing file: #{inputfile}, version: #{version}"

      raml = RAML.new(inputfile, ENV['baseuri'] || ENV['baseUri'] || false)
      sinces = {}
      raml.filternodes do |node, keys|
        if (node.has_key?('description') and node['description'].is_a?(String))
          nkey = keys.join('|')
          desc = node['description']
          since = desc.value_of('Since')
          vis = desc.value_of('Visibility').downcase

          # Strip tokens from description
          node['description'].gsub!(/\s*\[.*?\]\s*$/, '')

          # Reinstate the "Since" token for private RAMLs
          if (visibility == 'private')
            if (since.length < 1)
              # Pick the inherited since value
              start = keys.length - 1
              start.downto(1) do |len|
                ckey = keys.slice(0, len).join('|')
                if sinces.has_key?(ckey)
                  since = sinces[ckey]
                  break
                end
              end
            end
            since = '0.0' if since.length < 1
            sinces[nkey] = since
            node['description'] += " _[Since:#{since}]_" \
              if methods.include?(keys[-1].to_s)
          end

          # Drop nodes with a "since" value greater than specified version
          # or those with a visibility not matching specified value
          since.greaterThanVersion(version) \
            || (vis.length > 0 && visibility_filter && vis != visibility_filter)
        end
      end

      # Generate version-specific RAML file
      outversdir = File.join(outputdir, visibility, version)
      FileUtils.mkdir_p(outversdir) unless Dir.exists?(outversdir)

      outvers = File.join(outversdir, File.basename(inputfile))
      puts "Generating file: #{outvers}"
      File.open(outvers, 'w') do |f|
        collapse = ENV['collapse_empty'] || 'true'
        collapse = (collapse == 'true') # Convert to boolean
        f.write raml.dump(collapse)
      end

    end
  end

  if (manifest)
    if (File.exist?(manifest))
      puts "\nCopying #{visibility} RAMLs into release directories"
      releases = YAML.load(File.open(manifest))
      releases.keys.each do |rel|
        reldir = File.join(outputbase, 'releases', visibility, rel.to_s)
        FileUtils.mkdir_p(reldir)

        releases[rel].each do |r|
          api = r.keys.first
          vers = r[api]
          infile = File.join(outputbase, 'versions', visibility, vers.to_s, api + '.raml')
          outfile = File.join(reldir, api + '.raml')
          puts "Creating #{outfile} (version #{vers})"
          FileUtils.cp(infile, outfile)
        end
      end
    else
      STDERR.puts "WARNING: Release manifest not found: #{manifest}" unless File.exists?(manifest)
      STDERR.puts "         Not generating release-specific versions"
    end
  end
end
