#!/usr/bin/python2.4
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Unit tests for the util module."""


__author__ = 'davidbyttow@google.com (David Byttow)'


require 'test/unit'

require 'document'
require 'util'


class TestUtils  < Test::Unit::TestCase
  """Tests utility functions."""

  def testIsListOrDict()
    assert(Util.IsListOrDict([]))
    assert(Util.IsListOrDict({}))
    # assert(Util.IsListOrDict(set()))
    # assert(Util.IsListOrDict(()))
    assert(!Util.IsListOrDict(42))
    assert(!Util.IsListOrDict('list?'))
    assert(!Util.IsListOrDict(Object))
  end

  def testIsDict()
    assert(!Util.IsDict([]))
    assert(Util.IsDict({}))
    # assert(!Util.IsDict(set()))
    # assert(!Util.IsDict(()))
    assert(!Util.IsDict(42))
    assert(!Util.IsDict('dict?'))
    assert(!Util.IsDict(Object))
  end

  def testIsInstance()
    randomClass = Class.new

    assert(Util.IsInstance(randomClass))
    assert(!Util.IsInstance({}))
    assert(!Util.IsInstance(()))
    assert(!Util.IsInstance(42))
    assert(!Util.IsInstance('instance?'))
  end

  def testCollapseJavaCollections()
    def MakeList(e0=1)
      return {
          'javaClass' => 'java.util.ArrayList',
          'list' => [e0, 2, 3]
      }
    end

    def MakeMap(v='value')
      return {
          'javaClass' => 'java.util.HashMap',
          'map' => {'key' => v}
      }
    end

    l = Util.CollapseJavaCollections(MakeList())
    assert_equal(2, l[1])

    m = Util.CollapseJavaCollections(MakeMap())
    assert_equal('value', m['key'])

    nested = Util.CollapseJavaCollections(MakeMap(MakeList(MakeMap())))
    assert_equal('value', nested['key'][0]['key'])
  end

  def testToLowerCamelCase()
    assert_equal('foo', Util.ToLowerCamelCase('foo'))
    assert_equal('fooBar', Util.ToLowerCamelCase('foo_bar'))
    assert_equal('fooBar', Util.ToLowerCamelCase('foo__bar'))
    assert_equal('fooBarBaz', Util.ToLowerCamelCase('foo_bar_baz'))
    assert_equal('f', Util.ToLowerCamelCase('f'))
    assert_equal('f', Util.ToLowerCamelCase('f_'))
    assert_equal('', Util.ToLowerCamelCase(''))
    assert_equal('', Util.ToLowerCamelCase('_'))
    assert_equal('aBCDEF', Util.ToLowerCamelCase('_a_b_c_d_e_f_'))
  end

  def assertListsEqual(a, b)
    assert_equal(a.length, b.length)
    a.length.times do |i|
      assert_equal(a[i], b[i])
    end
  end

  def assertDictsEqual(a, b)
    assert_equal(a.keys().length, b.keys().length)
    a.each_pair do |k, v|
      assert_equal(v, b[k])
    end
  end

  def testSerializeList()
    data = [1, 2, 3]
    output = Util.Serialize(data)
    assert_equal('java.util.ArrayList', output['javaClass'])
    self.assertListsEqual(data, output['list'])
  end

  def testSerializeDict()
    data = {'key' => 'value'}
    output = Util.Serialize(data)
    assert_equal('java.util.HashMap', output['javaClass'])
    self.assertDictsEqual(data, output['map'])
  end

  class Data
    JAVA_CLASS = 'json.org.JSONObject'
    attr_accessor :public, :_protected, :__private

    def initialize()
      self.public = 1
      self._protected = 2
      self.__private = 3
    end

    def Func()
      nil
    end
  end

  def testSerializeAttributes()
    data = Data.new()
    output = Util.Serialize(data)
    # Functions and non-public fields should not be serialized.
    assert_equal(2, output.keys().length)
    assert_equal(Data::JAVA_CLASS, output['javaClass'])
    assert_equal(data.public, output['public'])
  end

  def testClipRange()
    def R(x, y)
      return Range.new(x, y)
    end

    def Test(test_range, clipping_range, expected)
      ret = Util.ClipRange(test_range, clipping_range)
      assert_equal(expected.length, ret.length)
      ret.length.times do |i|
        assert_equal(expected[i].first, ret[i].first)
        assert_equal(expected[i].end, ret[i].end)
      end
    end

    # completely out
    Test(R(0, 1), R(2, 3), [R(0, 1)])
    # completely out
    Test(R(3, 4), R(2, 3), [R(3, 4)])
    # completely in
    Test(R(2, 3), R(1, 4), [])
    # completely in
    Test(R(1, 4), R(1, 4), [])
    # tRim left
    Test(R(1, 3), R(2, 4), [R(1, 2)])
    # tRim Right
    Test(R(2, 4), R(1, 3), [R(3, 4)])
    # split with two
    Test(R(1, 4), R(2, 3), [R(1, 2), R(3, 4)])
    # split with one
    Test(R(1, 4), R(1, 3), [R(3, 4)])
  end
end
