#!/usr/bin/python2.4
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Unit tests for the ops module."""


__author__ = 'davidbyttow@google.com (David Byttow)'


require 'test/unit'

require 'document'
require 'model'
require 'ops'


class TestOperation < Test::Unit::TestCase
  """Test case for Operation class."""

  def testDefaults()
    op = Operation.new(WAVELET_APPEND_BLIP, 'wave-id', 'wavelet-id')
    assert_equal(WAVELET_APPEND_BLIP, op.type)
    assert_equal('wave-id', op.wave_id)
    assert_equal('wavelet-id', op.wavelet_id)
    assert_equal('', op.blip_id)
    assert_equal(-1, op.index)
    assert_equal(nil, op.property)
  end

  def testFields()
    op = Operation.new(DOCUMENT_INSERT, 'wave-id', 'wavelet-id',
                       blip_id='blip-id',
                       index=1,
                       prop='foo')
    assert_equal(DOCUMENT_INSERT, op.type)
    assert_equal('wave-id', op.wave_id)
    assert_equal('wavelet-id', op.wavelet_id)
    assert_equal('blip-id', op.blip_id)
    assert_equal(1, op.index)
    assert_equal('foo', op.property)
  end
end

module TestOpBasedClasses
  """Base class for op-based test classes. Sets up some test data."""

  def setup()
    @test_context = ContextImpl_.new()

    wave_data = Model::WaveData.new()
    wave_data.id = 'my-wave'
    wave_data.wavelet_ids = ['wavelet-1']
    @test_wave_data = wave_data
    @test_wave = @test_context.AddWave(wave_data)

    wavelet_data = Model::WaveletData.new()
    wavelet_data.creator = 'creator@google.com'
    wavelet_data.creation_time = 100
    wavelet_data.last_modified_time = 101
    wavelet_data.participants = ['robot@google.com']
    wavelet_data.root_blip_id = 'blip-1'
    wavelet_data.wave_id = wave_data.id
    wavelet_data.wavelet_id = 'wavelet-1'
    @test_wavelet_data = wavelet_data
    @test_wavelet = @test_context.AddWavelet(wavelet_data)

    blip_data = Model::BlipData.new()
    blip_data.blip_id = wavelet_data.root_blip_id
    blip_data.content = '<p>testing</p>'
    blip_data.contributors = [wavelet_data.creator, 'robot@google.com']
    blip_data.creator = wavelet_data.creator
    blip_data.last_modified_time = wavelet_data.last_modified_time
    blip_data.parent_blip_id = nil
    blip_data.wave_id = wave_data.id
    blip_data.wavelet_id = wavelet_data.wavelet_id
    @test_blip_data = blip_data
    @test_blip = @test_context.AddBlip(blip_data)
  end
end

class TestOpBasedContext < Test::Unit::TestCase
  """Test case for testing the operation-based context class, _ContextImpl."""
  include TestOpBasedClasses

  def testVerifySetup()
    assert_equal(@test_wave_data,
                      @test_context.GetWaveById('my-wave')._data)
    assert_equal(@test_wavelet_data,
                      @test_context.GetWaveletById('wavelet-1')._data)
    assert_equal(@test_blip_data,
                      @test_context.GetBlipById('blip-1')._data)
  end

  def testRemove()
    @test_context.RemoveWave('my-wave')
    assert_equal(nil, @test_context.GetWaveById('my-wave'))
    @test_context.RemoveWavelet('wavelet-1')
    assert_equal(nil, @test_context.GetWaveletById('wavelet-1'))
    @test_context.RemoveBlip('blip-1')
    assert_equal(nil, @test_context.GetBlipById('blip-1'))
  end
end

class TestOpBasedWave < Test::Unit::TestCase
  """Test case for OpBasedWave class."""
  include TestOpBasedClasses

  def testCreateWavelet()
    assert_raise(NotImplementedError) do
      @test_wave.CreateWavelet
    end
  end
end

class TestOpBasedWavelet < Test::Unit::TestCase
  """Test case for OpBasedWavelet class."""
  include TestOpBasedClasses

  def testCreateBlip()
    blip = @test_wavelet.CreateBlip()
    assert_equal('my-wave', blip.GetWaveId())
    assert_equal('wavelet-1', blip.GetWaveletId())
    assert_match /^TBD/, blip.GetId()
    assert_equal(blip, @test_context.GetBlipById(blip.GetId()))
  end

  def testAddParticipant()
    p = 'newguy@google.com'
    @test_wavelet.AddParticipant(p)
    assert(@test_wavelet.GetParticipants().include? p)
  end

  def testRemoveSelf()
    assert_raise(NotImplementedError) do
      @test_wavelet.RemoveSelf
    end
  end

  def testSetDataDocument()
    @test_wavelet.SetDataDocument('key', 'value')
    assert_equal('value', @test_wavelet.GetDataDocument('key'))
  end

  def testSetTitle()
    assert_raise(NotImplementedError) do
      @test_wavelet.SetTitle('foo')
    end
  end
end

class TestOpBasedBlip < Test::Unit::TestCase
  """Test case for OpBasedBlip class."""
  include TestOpBasedClasses

  def testCreateChild()
    blip = @test_blip.CreateChild()
    assert_equal('my-wave', blip.GetWaveId())
    assert_equal('wavelet-1', blip.GetWaveletId())
    assert_match /^TBD/, blip.GetId()
    assert_equal(blip, @test_context.GetBlipById(blip.GetId()))
  end

  def testDelete()
    @test_blip.Delete()
    assert_equal(nil,
                      @test_context.GetBlipById(@test_blip.GetId()))
  end
end

class TestOpBasedDocument < Test::Unit::TestCase
  """Test case for OpBasedDocument class."""
  include TestOpBasedClasses

  def setup()
    super
    @test_doc = @test_blip.GetDocument()
    @test_doc.SetText('123456')
  end

  def testSetText()
    text = 'Hello test.'
    assert(@test_doc.GetText() != text)
    @test_doc.SetText(text)
    assert_equal(text, @test_doc.GetText())
  end

  def testSetTextInRange()
    text = 'abc'
    @test_doc.SetTextInRange(Range.new(0, 2), text)
    assert_equal('abc456', @test_doc.GetText())
    @test_doc.SetTextInRange(Range.new(2, 2), text)
    assert_equal('ababc456', @test_doc.GetText())
  end

  def testAppendText()
    text = '789'
    @test_doc.AppendText(text)
    assert_equal('123456789', @test_doc.GetText())
  end

  def testClear()
    @test_doc.Clear()
    assert_equal('', @test_doc.GetText())
  end

  def testDeleteRange()
    @test_doc.DeleteRange(Range.new(0, 1))
    assert_equal('3456', @test_doc.GetText())
    @test_doc.DeleteRange(Range.new(0, 0))
    assert_equal('456', @test_doc.GetText())
  end

  def testAnnotateDocument()
    @test_doc.AnnotateDocument('key', 'value')
    assert(@test_doc.HasAnnotation('key'))
    assert(!@test_doc.HasAnnotation('non-existent-key'))
  end

  def testSetAnnotation()
    @test_doc.SetAnnotation(Range.new(0, 1), 'key', 'value')
    assert(@test_doc.HasAnnotation('key'))
  end

  def testDeleteAnnotationByName()
    assert_raise(NotImplementedError) do
      @test_doc.DeleteAnnotationsByName('key')
    end
  end

  def testDeleteAnnotationInRange()
    assert_raise(NotImplementedError) do
      @test_doc.DeleteAnnotationsInRange(Range.new(0, 1), 'key')
    end
  end

  def testAppendInlineBlip()
    blip = @test_doc.AppendInlineBlip()
    assert_equal('my-wave', blip.GetWaveId())
    assert_equal('wavelet-1', blip.GetWaveletId())
    assert_match /^TBD/, blip.GetId()
    assert_equal(@test_blip.GetId(), blip.GetParentBlipId())
    assert_equal(blip, @test_context.GetBlipById(blip.GetId()))
  end

  def testDeleteInlineBlip()
    blip = @test_doc.AppendInlineBlip()
    @test_doc.DeleteInlineBlip(blip.GetId())
    assert_equal(nil, @test_context.GetBlipById(blip.GetId()))
  end

  def testInsertInlineBlip()
    blip = @test_doc.InsertInlineBlip(1)
    assert_equal('my-wave', blip.GetWaveId())
    assert_equal('wavelet-1', blip.GetWaveletId())
    assert_match /^TBD/, blip.GetId()
    assert_equal(@test_blip.GetId(), blip.GetParentBlipId())
    assert_equal(blip, @test_context.GetBlipById(blip.GetId()))
  end

  def testAppendElement()
    @test_doc.AppendElement("GADGET")
  end
end
