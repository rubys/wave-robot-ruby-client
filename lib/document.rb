#!/usr/bin/ruby
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Defines document-based classes.

This module defines classes that are used to modify and describe documents and
their operations.
"""

__author__ = 'davidbyttow@google.com (David Byttow)'

require 'util'


# class Range(object)
# JAVA_CLASS = 'com.google.wave.api.Range'


class Annotation
  """Represents an annotation on a document.

  Annotations are key/value pairs over a range of content. Annotations
  can be used to store data or to be interpreted by a client when displaying
  the data.
  """
  attr_reader :range, :name, :value

  JAVA_CLASS = 'com.google.wave.api.Annotation'

  def initialize(name, value, r=nil)
    """Initializes this annotation with a name and value pair and a range.

    Args:
      name: Key name for this annotation.
      value: Value of this annotation.
      r: Range that this annotation is valid over.
    """
    @name = name
    @value = value
    @range = r || Range.new(0,1)
  end
end

class StringEnum
  """Enum like class that is configured with a list of values.

  This class effectively implements an enum for Elements, except for that
  the actual values of the enums will be the string values."""

  def self.enum(*values)
    values.each {|name| const_set(name.to_sym, name)}
  end
end


class ELEMENT_TYPE < StringEnum
  enum 'INLINE_BLIP', 'INPUT', 'CHECK', 'LABEL', 'BUTTON'
  enum 'RADIO_BUTTON', 'RADIO_BUTTON_GROUP','PASSWORD', 'GADGET', 'IMAGE'
end


class Element
  """Elements are non-text content within a document.

  These are generally abstracted from the Robot. Although a Robot can query the
  properties of an element it can only interact with the specific types that
  the element represents.

  Properties of elements are both accesible directly (image.url) and through
  the properties dictionary (image.properties['url']). In general Element
  should not be instantiated by robots, but rather rely on the derrived classes.
  """
  attr_accessor :type

  JAVA_CLASS = 'com.google.wave.api.Element'

  def initialize(element_type, properties)
    """Initializes self with the specified type and any properties."""
    @type = element_type
    properties.each_pair do |key, val|
      eval <<-EOD
        def #{key}
          @#{key}
        end
        def #{key}=(value)
          @#{key}=value
        end
        @#{key}=val
      EOD
    end
  end

  def Serialize()
    """Custom serializer for Elements.

    Element need their non standard attributes returned in a dict named
    properties.
    """
    props = {}
    data = {}
    for attr in self.methods
      next if Object.respond_to? attr
      next unless method(attr).arity == 0
      next if attr == 'Serialize'
      val = send(attr)
      next if val == self
      next if val == nil
      val = Util.Serialize(val)
      props[attr] = val
    end
    data['java_class'] = self.class::JAVA_CLASS
    data['type'] = type
    data['properties'] = Util.Serialize(props)
    return data
  end
end


class FormElement < Element

  JAVA_CLASS = 'com.google.wave.api.FormElement'

  def initialize(element_type, name, properties={})
    defaults = {:name=>name, :value=>'', :default_value=>'', :label=>''}
    super(element_type, defaults.merge(properties))
  end
end

class Gadget < Element

  JAVA_CLASS = 'com.google.wave.api.Gadget'

  def initialize(url='')
    super(ELEMENT_TYPE::GADGET, :url=>url)
  end
end

class Image < Element

  JAVA_CLASS = 'com.google.wave.api.Image'

  def initialize(url='', properties={})
    defaults = {:url=>url, :width=>nil, :height=>nil,
      :attachment_id=>nil, :caption=>nil}
    super(ELEMENT_TYPE::IMAGE, defaults.merge(properties))
  end
end
