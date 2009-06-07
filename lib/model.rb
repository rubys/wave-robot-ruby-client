#!/usr/bin/python2.4
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Defines classes that represent parts of the common wave model.

Defines the core data structures for the common wave model. At this level,
models are read-only but can be modified through operations.
"""

__author__ = 'davidbyttow@google.com (David Byttow)'


require 'document'
require 'logger'

module Model
  ROOT_WAVELET_ID_SUFFIX = '!conv+root'


  class WaveData
    """Defines the data for a single wave."""
    attr_accessor :id, :wavelet_ids

    def initialize()
      @id = nil
      @wavelet_ids = []
    end
  end

  class Wave
    """Models a single wave instance.

    A single wave is composed of its id and any wavelet ids that belong to it.
    """

    attr_reader :_data

    def initialize(data)
      """Inits this wave with its data.

      Args:
        data: A WaveData instance.
      """

      @_data = data
    end

    def GetId()
      """Returns this wave's id."""
      return @_data.id
    end

    def GetWaveletIds()
      """Returns a set of wavelet ids."""
      return @_data.wavelet_ids
    end
  end

  class WaveletData
    """Defines the data for a single wavelet."""

    JAVA_CLASS = 'com.google.wave.api.impl.WaveletData'
    attr_accessor :creator, :creation_time, :data_documents
    attr_accessor :last_modified_time, :participants, :root_blip_id
    attr_accessor :title, :version, :wave_id, :wavelet_id

    def initialize()
      @creator = nil
      @creation_time = 0
      @data_documents = {}
      @last_modified_time = 0
      @participants = []
      @root_blip_id = nil
      @title = ''
      @version = 0
      @wave_id = nil
      @wavelet_id = nil
    end
  end

  class Wavelet
    """Models a single wavelet instance.

    A single wavelet is composed of metadata, participants and the blips it
    contains.
    """

    attr_reader :_data

    def initialize(data)
      """Inits this wavelet with its data.

      Args:
        data: A WaveletData instance.
      """
      @_data = data
    end

    def GetCreator()
      """Returns the participant id of the creator of this wavelet."""
      return @_data.creator
    end

    def GetCreationTime()
      """Returns the time that this wavelet was first created in milliseconds."""
      return @_data.creation_time
    end

    def GetDataDocument(name, default=nil)
      """Returns a data document for this wavelet based on key name."""
      return @_data.data_documents.fetch(name, default)
    end

    def GetId()
      """Returns this wavelet's id."""
      return @_data.wavelet_id
    end

    def GetLastModifiedTime()
      """Returns the time that this wavelet was last modified in milliseconds."""
      return @_data.last_modified_time
    end

    def GetParticipants()
      """Returns a set of participants on this wavelet."""
      return @_data.participants
    end

    def GetRootBlipId()
      """Returns this wavelet's root blip id."""
      return @_data.root_blip_id
    end

    def GetTitle()
      """Returns the title of this wavelet."""
      return @_data.title
    end

    def GetWaveId()
      """Returns this wavelet's parent wave id."""
      return @_data.wave_id
    end
  end

  class BlipData
    """Data that describes a single blip."""

    JAVA_CLASS = 'com.google.wave.api.impl.BlipData'
    attr_accessor :annotations, :child_blip_ids, :content, :contributors
    attr_accessor :creator, :elements, :last_modified_time, :parent_blip_id
    attr_accessor :blip_id, :version, :wave_id, :wavelet_id

    def initialize()
      @annotations = []
      @blip_id = nil
      @child_blip_ids = []
      @content = ''
      @contributors = []
      @creator = nil
      @elements = {}
      @last_modified_time = 0
      @parent_blip_id = nil
      @version = -1
      @wave_id = nil
      @wavelet_id = nil
    end
  end

  class Blip
    """Models a single blip instance.

    Blips are essentially elements of conversation. Blips can live in a
    hierarchy of blips. A root blip has no parent blip id, but all blips
    have the ids of the wave and wavelet that they are associated with.

    Blips also contain annotations, content and elements, which are accessed via
    the Document object.
    """

    def initialize(data, doc)
      """Inits this blip with its data and document view.

      Args:
        data: A BlipData instance.
        doc: A Document instance associated with this blip.
      """
      @_data = data
      @_document = doc
    end

    def GetChildBlipIds()
      """Returns a set of blip ids that are children of this blip."""
      return @_data.child_blip_ids
    end

    def GetContributors()
      """Returns a set of participant ids that contributed to this blip."""
      return @_data.contributors
    end

    def GetCreator()
      """Returns the id of the participant that created this blip."""
      return @_data.creator
    end

    def GetDocument()
      """Returns the Document of this blip, which contains content data."""
      return @_document
    end

    def GetId()
      """Returns the id of this blip."""
      return @_data.blip_id
    end

    def GetLastModifiedTime()
      """Returns the time that this blip was last modified by the server."""
      return @_data.last_modified_time
    end

    def GetParentBlipId()
      """Returns the id of this blips parent or nil if it is the root."""
      return @_data.parent_blip_id
    end

    def GetWaveId()
      """Returns the id of the wave that this blip belongs to."""
      return @_data.wave_id
    end

    def GetWaveletId()
      """Returns the id of the wavelet that this blip belongs to."""
      return @_data.wavelet_id
    end

    def IsRoot()
      """Returns True if this is the root blip of a wavelet."""
      return @_data.parent_blip_id == nil
    end
  end

  class Document
    """Base representation of a document of a blip.

    TODO(davidbyttow): Add support for annotations and elements.
    """

    def initialize(blip_data)
      """Inits this document with the data of the blip it is representing.

      Args:
        blip_data: A BlipData instance.
      """
      @_blip_data = blip_data
    end

    def GetText()
      """Returns the raw text content of this document."""
      return @_blip_data.content
    end
  end

  class Event
    """Data describing a single event."""
    attr_accessor :type, :timestamp, :modified_by, :properties

    def initialize()
      @type = ''
      @timestamp = 0
      @modified_by = ''
      @properties = {}
    end
  end

  def self.CreateEvent(data)
    """Construct event data from the raw incoming wire protocol."""
    event = Event.new()
    event.type = data['type']
    event.timestamp = data['timestamp']
    event.modified_by = data['modifiedBy']
    event.properties = data['properties'] or {}
    return event
  end

  def self.CreateWaveletData(data)
    """Construct wavelet data from the raw incoming wire protocol.

    TODO(davidbyttow): Automate this based on naming like the Serialize methods.

    Args:
      data: Serialized data from server.

    Returns:
      Instance of WaveletData based on the fields.
    """
    wavelet_data = WaveletData.new()
    wavelet_data.creator = data['creator']
    wavelet_data.creation_time = data['creationTime']
    wavelet_data.data_documents = data['dataDocuments'] or {}
    wavelet_data.last_modified_time = data['lastModifiedTime']
    wavelet_data.participants = data['participants']
    wavelet_data.root_blip_id = data['rootBlipId']
    wavelet_data.title = data['title']
    wavelet_data.version = data['version']
    wavelet_data.wave_id = data['waveId']
    wavelet_data.wavelet_id = data['waveletId']
    return wavelet_data
  end

  def self.CreateBlipData(data)
    """Construct blip data from the raw incoming wire protocol.

    TODO(davidbyttow): Automate this based on naming like the Serialize methods.

    Args:
      data: Serialized data from server.

    Returns:
      Instance of BlipData based on the fields.
    """
    blip_data = BlipData.new()
    blip_data.annotations = []
    for annotation in data['annotations']
      r = Range.new(annotation['range']['start'], annotation['range']['end'])
      blip_data.annotations.push(Annotation.new(annotation['name'],
                                                annotation['value'],
                                                :r=>r))
    end
    blip_data.child_blip_ids = data['childBlipIds']
    blip_data.content = data['content']
    blip_data.contributors = data['contributors']
    blip_data.creator = data['creator']
    blip_data.elements = data['elements']
    blip_data.last_modified_time = data['lastModifiedTime']
    blip_data.parent_blip_id = data['parentBlipId']
    blip_data.blip_id = data['blipId']
    blip_data.version = data['version']
    blip_data.wave_id = data['waveId']
    blip_data.wavelet_id = data['waveletId']
    return blip_data
  end

  class Context
    """Contains information associated with a single request from the server.

    This includes the current waves in this session
    and any operations that have been enqueued during request processing.
    """

    def initialize()
      @_waves = {}
      @_wavelets = {}
      @_blips = {}
      @_operations = []
    end

    def GetBlipById(blip_id)
      """Returns a blip by id or nil if it does not exist."""
      return @_blips[blip_id]
    end

    def GetWaveById(wave_id)
      """Returns a wave by id or nil if it does not exist."""
      return @_waves[wave_id]
    end

    def GetWaveletById(wavelet_id)
      """Returns a wavelet by id or nil if it does not exist."""
      return @_wavelets[wavelet_id]
    end

    def GetRootWavelet()
      """Returns the root wavelet or nil if it is not in this context."""
      for wavelet in @_wavelets.values()
        wavelet_id = wavelet.GetId()
        if wavelet_id[-ROOT_WAVELET_ID_SUFFIX.length .. -1] == ROOT_WAVELET_ID_SUFFIX
          return wavelet
        end
      end
      logging.warning("Could not retrieve root wavelet.")
      return nil
    end

    def GetWaves()
      """Returns the list of waves associated with this session."""
      return @_waves.values()
    end

    def GetWavelets()
      """Returns the list of wavelets associated with this session."""
      return @_wavelets.values()
    end

    def GetBlips()
      """Returns the list of blips associated with this session."""
      return @_blips.values()
    end
  end
end
