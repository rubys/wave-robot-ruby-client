#!/usr/bin/ruby
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Unit tests for the document module."""


__author__ = 'davidbyttow@google.com (David Byttow)'


require 'test/unit'

require 'document'
require 'util'


# class TestRange < Test::Unit::TestCase
#  """Tests for the Range class."""
#
#  def testDefaults()
#    r = Range.new()
#    assert_equal(0, r.first)
#    assert_equal(1, r.last)
#  end
#
#  def testValidRanges()
#    r = Range.new(1, 2)
#    assert_equal(1, r.first)
#    assert_equal(2, r.last)
#  end
#
#  def testInvalidRanges()
#    self.assertRaises(ValueError, Range, 1, 0)
#    self.assertRaises(ValueError, Range, 0, -1)
#    self.assertRaises(ValueError, Range, 3, 1)
#  end
#
# def testCollapsedRanges()
#    self.assertTrue(Range.new(0, 0).IsCollapsed())
#    self.assertTrue(Range.new(1, 1).IsCollapsed())
#  end
#end

class TestAnnotation < Test::Unit::TestCase
  """Tests for the Annotation class."""

  def testDefaults()
    annotation = Annotation.new('key', 'value')
    assert_equal(Range.new(0,1).first, annotation.range.first)
    assert_equal(Range.new(0,1).last, annotation.range.last)
  end

  def testFields()
    annotation = Annotation.new('key', 'value', Range.new(2, 3))
    assert_equal('key', annotation.name)
    assert_equal('value', annotation.value)
    assert_equal(2, annotation.range.first)
    assert_equal(3, annotation.range.last)
  end
end

class TestElement < Test::Unit::TestCase
  """Tests for the Element class."""

  def testProperties()
    element = Element.new(ELEMENT_TYPE::GADGET, :key=>'value')
    assert_equal('value', element.key)
  end

  def testFormElement()
    element = FormElement.new(ELEMENT_TYPE::INPUT, 'input', :label=>'label')
    assert_equal(ELEMENT_TYPE::INPUT, element.type)
    assert_equal(element.value, '')
    assert_equal(element.name, 'input')
    assert_equal(element.label, 'label')
  end

  def testImage()
    image = Image.new('http://test.com/image.png', :width=>100, :height=>100)
    assert_equal(ELEMENT_TYPE::IMAGE, image.type)
    assert_equal(image.url, 'http://test.com/image.png')
    assert_equal(image.width, 100)
    assert_equal(image.height, 100)
  end

  def testGadget()
    gadget = Gadget.new('http://test.com/gadget.xml')
    assert_equal(ELEMENT_TYPE::GADGET, gadget.type)
    assert_equal(gadget.url, 'http://test.com/gadget.xml')
  end

  def testSerialize()
    image = Image.new('http://test.com/image.png', :width=>100, :height=>100)
    s = Util.Serialize(image)
    # we should really only have three things to serialize
    assert_equal(['java_class', 'properties', 'type'], s.keys.sort)
    assert_equal(s['java_class'], 'com.google.wave.api.Image')
    assert_equal(s['properties']['javaClass'], 'java.util.HashMap')
    props = s['properties']['map']
    assert_equal(props.length, 3)
    assert_equal(props['url'], 'http://test.com/image.png')
    assert_equal(props['width'], 100)
    assert_equal(props['height'], 100)
  end
end
