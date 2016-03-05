require 'fileutils'
require 'json'
require 'open-uri'
require 'stringio'
require 'yaml'

DEBUG = false
INHERITED_PARAMS = {
  'is' => Array,
  'urlParameters' => Hash,
}

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
      s = since
      desc += " [Since:#{s}]"
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

  def method_missing(method, *args, &block)
    return @obj[method] if @obj.has_key?(method)
    return @obj[method.to_s] if @obj.has_key?(method.to_s)
    return '' if method == 'description' or method.to_s == 'description'
    raise "Unknown attribute: #{method.to_s}"
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

#Adding Module to return values in 'is' node within a resource. Change is to allow Unsecured flows as well.[Naveen:29-02-2016]
module FlowTypeIdentifier
    
  def fetchFlowType
    isValue = @obj.has_key?('is') ? @obj['is']:[]
	localFlowtype = ""
	unless isValue.nil?	
		for i in 0..isValue.length
		  if (isValue[i] == 'unsecured' or isValue[i] == 'secured')
			localFlowtype = isValue[i]
		  end
		end
	end	
    localFlowtype
  end
end

class Resource
  include DescriptionParser
  include FlowTypeIdentifier

  def initialize(dict, uri='', inheritedSince='0.0', inheritedVisibility='public', inheritedFlowType='secured')
    @uri = uri
    @obj = dict
    localSince = value_of('since')
    @since = localSince.greaterThanVersion(inheritedSince) \
           ? localSince \
           : inheritedSince
    localVisibility = value_of('visibility')
    
    if (inheritedVisibility == 'private')
      @visibility = inheritedVisibility
    elsif (localVisibility.length > 0)
      @visibility = localVisibility
    else
      @visibility = 'public'
    end

    localFlowtype = fetchFlowType
    if (localFlowtype.length > 0)
      @flowtype = localFlowtype
    else
      @flowtype = inheritedFlowType
    end    
  end

  def resources
    @obj.keys.grep(/^\//).map {|e| Resource.new(@obj[e], File.join(@uri, e), @since, @visibility, @flowtype)}
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
    @obj.keys.find_all{|k| k =~ /^(get|put|post|delete)$/}.map{|e| Action.new(@obj[e], e, @since, @visibility, @flowtype)}
  end

  def drop_resource(res)
    @obj.delete_if {|key, value| key == res.uri}
  end

  def drop_action(action)
    @obj.delete_if {|key, value| key == action.type}
  end

  attr_reader :since, :uri, :visibility, :flowtype

end

class Action
  include DescriptionParser
  include FlowTypeIdentifier

  def initialize(dict, type, inheritedSince='0.0', inheritedVisibility='public', inheritedFlowType='secured')
    @type = type
    @obj = dict
    localSince = value_of('since')
    @since = localSince.greaterThanVersion(inheritedSince) \
           ? localSince \
           : inheritedSince
    localVisibility = value_of('visibility')
    if (inheritedVisibility == 'private')
      @visibility = inheritedVisibility
    elsif (localVisibility.length > 0)
      @visibility = localVisibility
    else
      @visibility = 'public'
    end
	
	localFlowtype = fetchFlowType
    if (localFlowtype.length > 0)
      @flowtype = localFlowtype
    else
      @flowtype = inheritedFlowType
    end
  end

  def headers
    return [] unless @obj.has_key?('headers') and @obj['headers'].is_a?(Hash)
    @obj['headers'].keys.map {|k| Header.new(@obj['headers'][k], k, @since, @visibility)}
  end

  def responses
    return [] unless @obj.has_key?('responses')
    @obj['responses'].keys.map {|k| Response.new(@obj['responses'][k], k, @since, @visibility)}
  end

  def drop_header(header)
    @obj['headers'].delete_if {|key, value| key == header.name}
  end

  def drop_response(response)
    @obj['responses'].delete_if {|key, value| key == response.code}
  end

  attr_reader :since, :type, :visibility, :flowtype

end

class Header
  include DescriptionParser

  def initialize(dict, name, inheritedSince='0.0', inheritedVisibility='public')
    @name = name
    @obj = dict
    localSince = value_of('since')
    @since = localSince.greaterThanVersion(inheritedSince) \
           ? localSince \
           : inheritedSince
    localVisibility = value_of('visibility')
    if (inheritedVisibility == 'private')
      @visibility = inheritedVisibility
    elsif (localVisibility.length > 0)
      @visibility = localVisibility
    else
      @visibility = 'public'
    end
  end

  attr_reader :name, :since, :visibility

end

class Response
  include DescriptionParser

  def initialize(dict, code, inheritedSince='0.0', inheritedVisibility='public')
    @code = code
    @obj = dict
    localSince = value_of('since')
    @since = localSince.greaterThanVersion(inheritedSince) \
           ? localSince \
           : inheritedSince
    localVisibility = value_of('visibility')
    if (inheritedVisibility == 'private')
      @visibility = inheritedVisibility
    elsif (localVisibility.length > 0)
      @visibility = localVisibility
    else
      @visibility = 'public'
    end
  end

  attr_reader :code, :since, :visibility

end

class RAML < Resource

  def initialize(infile, baseuri = false)
    @linenumbers = {}
    inputdir = File.dirname(infile)
    input = open(infile, 'r:UTF-8') do |f|
      inlined_raml = ''
      linenum = 0
      cumlinenum = 0
      f.readlines.each do |line|
        linenum += 1
        if (line !~ /^\s*#/ and line =~ /\!include\s+(.*)/)
          incfile = $1.strip
          incfile = File.join(inputdir, incfile) unless File.exists?(incfile)
          incfile.chomp!
          open(incfile) do |i|
            incline = 0
            i.readlines.each do |inc|
              inlined_raml += inc
              incline += 1
              cumlinenum += 1
              @linenumbers[cumlinenum] = [ incfile, incline ]
            end
          end
        else
          inlined_raml += line
          cumlinenum += 1
          @linenumbers[cumlinenum] = [ infile, linenum ]
        end
      end
      inlined_raml
    end

    data = {}
    begin
      data = YAML.load(input)
    rescue Exception => e
      re = /\sat\sline\s(\d+)\scolumn\s(\d+)/
      nmsg = e.message
      disclaimer = true
      if (e.message =~ re)
        line = $1.to_i
        column = $2
        if (@linenumbers.has_key?(line))
          nline = @linenumbers[line]
          nmsg = " starting at line #{nline[1]} column #{column} in file \"#{nline[0]}\""
          nmsg = e.message.dup.sub(re, nmsg)
          disclaimer = false
        end
      end
      STDERR.puts "Error parsing file: #{infile}: #{nmsg}"
      STDERR.puts "[NOTE] Reported line numbers may be incorrect because of !include sections" if disclaimer
      STDERR.puts
      raise e
    end

    %w( schemas ).each do |node|
      if (data.has_key?(node))
        data[node].each do |item|
          key = item.keys.first
          value = item[key]
          begin
            p = JSON.parse(value)
          rescue Exception => e
            abort "Error parsing JSON element in #{infile}: node \"#{node}\" > \"#{key}\": \"#{e.class}: #{e.message.split("\n").first}\"\n" +
                  "Please validate the JSON using something like http://jsonformatter.curiousconcept.com/"
          end
        end
      end
    end

    if (baseuri)
      repl = (baseuri =~ /^https?:/ ? "#{baseuri}\\2" : "\\1#{baseuri}\\2")
      data['baseUri'].sub!(/^(https?:\/\/)[^\/]+(.*)/, repl)
    end

    super(data)
  end

  def walknodes(&block)
    return _walknodes(@obj, [], :filter => false, &block)
  end

  def filternodes(&block)
    return _walknodes(@obj, [], :filter => true, &block)
  end

  def dump(collapse_paths = false)
    if (collapse_paths)
      _collapse_paths(@obj)
    else
      puts "Not collapsing empty paths"
    end
    raml = @obj.to_yaml
    raml.sub!(/^---/, "#%RAML 0.8");

    io = StringIO.new(raml)
    out = ''
    while (line = io.gets)
      line.chomp!
      if (line =~ /^(\s*)description:\s+(".*)/)
        (desc, line) = _fixdesc(io, "#{$1}description: #{$2}", $1)
        out += desc + "\n"
      end
      out += line + "\n"
    end

    return out
  end

  private

  def _fixdesc(io, line, spaces)
    out = line
    nline = ''
    while (nline = io.gets)
      nline.chomp!
      if (nline =~ /^#{spaces}\s+(.*)/)
        out += ' ' + $1
      else
        return out, nline
      end
    end
  end

  def _walknodes(node, keys, options={}, &block)
    return unless node.is_a?(Hash)

    do_filter = options[:filter] || false

    node.keys.each do |key|
      next unless node[key].is_a?(Hash)

      nkeys = keys + [key]
      drop_node = block.call(node[key], nkeys)
      if (do_filter and drop_node)
        node.delete(key)
      end

      _walknodes(node[key], nkeys, options, &block) if node.has_key?(key)
    end
  end

  def _collapse_paths(node)
    return unless node.is_a?(Hash)
    node.keys.each do |key|
      next unless key =~ /^\//
      subnode = node[key]
      if (not subnode.is_a?(Hash))
          STDERR.puts "Removing resource: #{key}" if DEBUG
      elsif _needs_collapsing(subnode)
        # Inherited values
        inherit = {}
        INHERITED_PARAMS.each do |p|
          inherit[p] = subnode[p] if subnode.has_key?(p)
        end
        subnode.keys.find_all {|k| k =~ /^\//}.each do |path|
          collapsed_path = File.join(key, path)
          STDERR.puts "Collapsing resource: #{collapsed_path}" if DEBUG
          subsubnode = subnode[path]
          INHERITED_PARAMS.keys.each do |p|
            next if not (inherit.has_key?(p) and subnode.has_key?(p))
            inherit[p] = INHERITED_PARAMS[p].new unless inherit.has_key?(p)
            subsubnode[p] = INHERITED_PARAMS[p].new unless subsubnode.has_key?(p)
            case INHERITED_PARAMS[p]
            when Array
              subsubnode[p] += inherit[p]
              subsubnode[p].uniq!
            when Hash
              subsubnode[p] = inherit.merge(subsubnode)
            else
              abort "Unknown parameter type: #{p}"
            end
          end
          node[collapsed_path] = subsubnode
        end
        node.delete(key)
        # Node has been modified; re-examine it
        _collapse_paths(node)
      else
        _collapse_paths(subnode)
      end
    end
  end

  def _needs_collapsing(node)
    methods = node.keys.find_all {|k| k =~ /^(?:get|put|post|delete)/}
    methods.empty?
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
