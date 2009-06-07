#!/usr/bin/python2.4
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Utility library containing various helpers used by the API.

Contains miscellaneous functions used internally by the API.
"""

__author__ = 'davidbyttow@google.com (David Byttow)'


require 'document'

module Util
  CUSTOM_SERIALIZE_METHOD_NAME = 'Serialize'

  def self.IsListOrDict(inst)
    """Returns whether or not this is a list, tuple, set or dict ."""
    return (inst.respond_to?(:each) and !inst.respond_to?(:each_char) and !inst.is_a?(String))
  end

  def self.IsDict(inst)
    """Returns whether or not the specified instance is a dict."""
    return inst.respond_to? :each_pair
  end

  def self.IsRange(inst)
    """Returns whether or not the specified instance is a range."""
    return inst.respond_to? :end
  end

  def self.IsInstance(obj)
    """Returns whether or not the specified instance is a user-defined type."""
    # NOTE(davidbyttow): This seems like a reasonably safe hack for now...
    # I'm not exactly sure how to test if something is a subclass of object.
    # And no, "is InstanceType" does not work here. :(
    [Hash, Array, String, Fixnum, Float, FalseClass, TrueClass, NilClass,
    Range].
      each do |builtin|
      return false if obj.instance_of?(builtin)
    end
    return true
  end

  def self.CollapseJavaCollections(data)
    """Collapses the unnecessary extra data structures in the wire format.

    Currently the wire format is built from marshalling of Java objects. This
    introduces overhead of extra key/value pairs with respect to collections and
    superfluous fields. As such, this method attempts to collapse those structures
    out of the data format by collapsing the collection objects and removing
    the java class fields.

    This preserves the data that is passed in and only removes the collection
    types.

    Args:
      data: Some arbitrary dict, list or primitive type.

    Returns:
      The same data structure with the collapsed and unnecessary objects
      removed.
    """
    if data.is_a? Hash
      java_class = data['javaClass']
      if java_class == 'java.util.HashMap'
        return CollapseJavaCollections(data['map'])
      elsif java_class == 'java.util.ArrayList'
        return CollapseJavaCollections(data['list'])
      end
	  h = Hash.new
      data.each_pair do |key, val|
        h[key] = CollapseJavaCollections(val)
      end
	  return h
	elsif data.is_a? Array
      return data.map{|val| CollapseJavaCollections(val)}
    end
	return data
  end

  def self.ToLowerCamelCase(s)
    """Converts a string to lower camel case.

    Examples
      foo => foo
      foo_bar => fooBar
      foo__bar => fooBar
      foo_bar_baz => fooBarBaz

    Args:
      s: The string to convert to lower camel case.

    Returns:
      The lower camel cased string.
    """
    s.gsub(/^_+/,'').gsub(/_+\w?/) {|s| s.gsub('_','').upcase}
  end

  DefaultKeyWriter = Proc.new do |key_name|
    """This key writer rewrites keys as lower camel case.

    Expects that the input is formed by '_' delimited words.

    Args:
      key_name: Name of the key to serialize.

    Returns:
      Key name in lower camel-cased form.
    """
    ToLowerCamelCase(key_name)
  end

  def self._SerializeAttributes(obj, key_writer=DefaultKeyWriter)
    """Serializes attributes of an instance.

    Iterates all attributes of an object and invokes serialize if they are
    public and not callable.

    Args:
      obj: The instance to serialize.
      key_writer: Optional function that takes a string key and optionally mutates
          it before serialization. For example:

          def randomize(key_name):
            return key_name += str(random.random())

    Returns:
      The serialized object.
    """
    data = {}
    for attr_name in obj.methods
      next if attr_name =~ /^[_A-Z]/ # naming conventions
      next if Object.respond_to?(attr_name)
      next unless obj.method(attr_name).arity == 0
      attr = obj.send(attr_name)
      next if attr == obj

      # Looks okay, serialize it.
	  data[key_writer.call(attr_name)] = Serialize(attr)
    end
	
    for attr_name in obj.instance_variables
      next if attr_name =~ /^@[_A-Z]/ # naming conventions
      next if Object.respond_to?(attr_name)
      attr = obj.instance_variable_get(attr_name)
      next if attr == obj

      # Looks okay, serialize it.
	  data[key_writer.call(attr_name.gsub('@',''))] = Serialize(attr)
    end	
	
    data['type']=Serialize(obj.type) if obj.respond_to?(:type=)
    if obj.class.constants.include? "JAVA_CLASS"
      data['javaClass']=obj.class.const_get(:JAVA_CLASS)
    end
    return data
  end

  def self._SerializeList(l)
    """Invokes Serialize on all of its elements.

    Args:
      l: The list object to serialize.

    Returns:
      The serialized list.
    """
    data = l.map {|v| Serialize(v)}

    return {
        'javaClass' => 'java.util.ArrayList',
        'list' => data
    }
  end

  def self._SerializeRange(r)
    """Serialize a Range object

    Args:
      r: The Range object to serialize.

    Returns:
      The serialized range.
    """
    return {
        'javaClass' => 'com.google.wave.api.Range',
        'start' => r.first,
        'end' => r.end
    }
  end


  def self._SerializeDict(d, key_writer=DefaultKeyWriter)
    """Invokes serialize on all of its key/value pairs.

    Args:
      d: The dict instance to serialize.
      key_writer: Optional key writer function.

    Returns:
      The serialized dict.
    """
    data = {}
    d.each_pair do |k, v|
      data[key_writer.call(k)] = Serialize(v)
    end
    return {
        'javaClass' => 'java.util.HashMap',
        'map' => data
    }
  end


  def self.Serialize(obj, key_writer=DefaultKeyWriter)
    """Serializes any instance.

    If this is a user-defined instance
    type, it will first check for a custom Serialize() function and use that
    if it exists. Otherwise, it will invoke serialize all of its public
    attributes. Lists and dicts are serialized trivially.

    Args:
      obj: The instance to serialize.
      key_writer: Optional key writer function.

    Returns:
      The serialized object.
    """
    if IsInstance(obj)
      if obj and obj.respond_to?(CUSTOM_SERIALIZE_METHOD_NAME)
        return obj.send(CUSTOM_SERIALIZE_METHOD_NAME)
      end
      return _SerializeAttributes(obj, key_writer)
    elsif IsListOrDict(obj)
      if IsDict(obj)
        return _SerializeDict(obj, key_writer)
      elsif IsRange(obj)
        return _SerializeRange(obj)
      else
        return _SerializeList(obj)
      end
    end
    return obj
  end

  def self.ClipRange(r, clip_range)
    """Clips one range to another.

    Given a range to be clipped and a clipping range, will result in a list
    of 0-2 new ranges. If the range is completely inside of the clipping range
    then an empty list will be returned. If it is completely outside, then
    a list with only the same range will be returned.

    Otherwise, other permutations may result in a single clipped range or
    two ranges that were the result of a split.

    Args:
      r: The range to be clipped.
      clip_range: The range that is clipping the other.

    Returns:
      A list of 0-2 ranges as a result of performing the clip.
    """
    # Check if completely outside the clipping range.
    if r.end <= clip_range.first or r.first >= clip_range.end
      return [r]
    end
    # Check if completely clipped.
    if r.first >= clip_range.first and r.end <= clip_range.end
      return []
    end
    # Check if split.
    if clip_range.first >= r.first and clip_range.end <= r.end
      splits = []
      if r.first < clip_range.first
        splits.push(Range.new(r.first, clip_range.first))
      end
      if clip_range.end < r.end
        splits.push(Range.new(clip_range.end, r.end))
      end
      return splits
    end
    # Just a trim.
    if clip_range.first < r.first
      return [Range.new(clip_range.end, r.end)]
    end
    return [Range.new(r.first, clip_range.first)]
  end
end
