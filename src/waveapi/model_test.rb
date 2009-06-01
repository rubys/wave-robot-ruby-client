#!/usr/bin/python2.4
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Unit tests for the model module."""


__author__ = 'davidbyttow@google.com (David Byttow)'


require 'test/unit'

require 'model'


class TestWaveModel < Test::Unit::TestCase
  """Tests the primary data structures for the wave model."""

  def setup()
    wave_data = Model::WaveData.new()
    wave_data.id = 'my-wave'
    wave_data.wavelet_ids = ['wavelet-1']
    @test_wave_data = wave_data

    wavelet_data = Model::WaveletData.new()
    wavelet_data.creator = 'creator@google.com'
    wavelet_data.creation_time = 100
    wavelet_data.last_modified_time = 101
    wavelet_data.participants = ['robot@google.com']
    wavelet_data.root_blip_id = 'blip-1'
    wavelet_data.wave_id = wave_data.id
    wavelet_data.wavelet_id = 'wavelet-1'
    @test_wavelet_data = wavelet_data

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
  end

  def testWaveFields()
    w = Model::Wave.new(@test_wave_data)
    assert_equal(@test_wave_data.id, w.GetId())
    assert_equal(@test_wave_data.wavelet_ids, w.GetWaveletIds())
  end

  def testWaveletFields()
    w = Model::Wavelet.new(@test_wavelet_data)
    assert_equal(@test_wavelet_data.creator, w.GetCreator())
  end

  def testBlipFields()
    b = Model::Blip.new(@test_blip_data, Model::Document.new(@test_blip_data))
    assert_equal(@test_blip_data.child_blip_ids,
                      b.GetChildBlipIds())
    assert_equal(@test_blip_data.contributors, b.GetContributors())
    assert_equal(@test_blip_data.creator, b.GetCreator())
    assert_equal(@test_blip_data.content,
                      b.GetDocument().GetText())
    assert_equal(@test_blip_data.blip_id, b.GetId())
    assert_equal(@test_blip_data.last_modified_time,
                      b.GetLastModifiedTime())
    assert_equal(@test_blip_data.parent_blip_id,
                      b.GetParentBlipId())
    assert_equal(@test_blip_data.wave_id,
                      b.GetWaveId())
    assert_equal(@test_blip_data.wavelet_id,
                      b.GetWaveletId())
    assert_equal(true, b.IsRoot())
  end

  def testBlipIsRoot()
    @test_blip_data.parent_blip_id = 'blip-parent'
    b = Model::Blip.new(@test_blip_data, Model::Document.new(@test_blip_data))
    assert_equal(false, b.IsRoot())
  end

  def testCreateEvent()
    data = {'type' => 'WAVELET_PARTICIPANTS_CHANGED',
            'properties' => {'blipId' => 'blip-1'},
            'timestamp' => 123,
            'modifiedBy' => 'modifier@google.com'}
    event_data = Model.CreateEvent(data)
    assert_equal(data['type'], event_data.type)
    assert_equal(data['properties'], event_data.properties)
    assert_equal(data['timestamp'], event_data.timestamp)
    assert_equal(data['modifiedBy'], event_data.modified_by)
  end
end
