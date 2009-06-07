#!/usr/bin/python2.4
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Support for operations that can be applied to the server.

Contains classes and utilities for creating operations that are to be
applied on the server.
"""

__author__ = 'davidbyttow@google.com (David Byttow)'


require 'document'
require 'model'
require 'util'
 
# Operation Types
WAVELET_APPEND_BLIP = 'WAVELET_APPEND_BLIP'
WAVELET_ADD_PARTICIPANT = 'WAVELET_ADD_PARTICIPANT'
WAVELET_CREATE = 'WAVELET_CREATE'
WAVELET_REMOVE_SELF = 'WAVELET_REMOVE_SELF'
WAVELET_DATADOC_SET = 'WAVELET_DATADOC_SET'
WAVELET_SET_TITLE = 'WAVELET_SET_TITLE'
BLIP_CREATE_CHILD = 'BLIP_CREATE_CHILD'
BLIP_DELETE = 'BLIP_DELETE'
DOCUMENT_ANNOTATION_DELETE = 'DOCUMENT_ANNOTATION_DELETE'
DOCUMENT_ANNOTATION_SET = 'DOCUMENT_ANNOTATION_SET'
DOCUMENT_ANNOTATION_SET_NORANGE = 'DOCUMENT_ANNOTATION_SET_NORANGE'
DOCUMENT_APPEND = 'DOCUMENT_APPEND'
DOCUMENT_APPEND_STYLED_TEXT = 'DOCUMENT_APPEND_STYLED_TEXT'
DOCUMENT_INSERT = 'DOCUMENT_INSERT'
DOCUMENT_DELETE = 'DOCUMENT_DELETE'
DOCUMENT_REPLACE = 'DOCUMENT_REPLACE'
DOCUMENT_ELEMENT_APPEND = 'DOCUMENT_ELEMENT_APPEND'
DOCUMENT_ELEMENT_DELETE = 'DOCUMENT_ELEMENT_DELETE'
DOCUMENT_ELEMENT_INSERT = 'DOCUMENT_ELEMENT_INSERT'
DOCUMENT_ELEMENT_INSERT_AFTER = 'DOCUMENT_ELEMENT_INSERT_AFTER'
DOCUMENT_ELEMENT_INSERT_BEFORE = 'DOCUMENT_ELEMENT_INSERT_BEFORE'
DOCUMENT_ELEMENT_REPLACE = 'DOCUMENT_ELEMENT_REPLACE'
DOCUMENT_INLINE_BLIP_APPEND = 'DOCUMENT_INLINE_BLIP_APPEND'
DOCUMENT_INLINE_BLIP_DELETE = 'DOCUMENT_INLINE_BLIP_DELETE'
DOCUMENT_INLINE_BLIP_INSERT = 'DOCUMENT_INLINE_BLIP_INSERT'
DOCUMENT_INLINE_BLIP_INSERT_AFTER_ELEMENT = ('DOCUMENT_INLINE_BLIP_INSERT_'
                                             'AFTER_ELEMENT')


class Operation
  """Represents a generic operation applied on the server.

  This operation class contains data that is filled in depending on the
  operation type.

  It can be used directly, but doing so will not result
  in local, transient reflection of state on the blips. In other words,
  creating a 'delete blip' operation will not remove the blip from the local
  context for the duration of this session. It is better to use the OpBased
  model classes directly instead.
  """

  JAVA_CLASS = 'com.google.wave.api.impl.OperationImpl'
  attr_accessor :type, :wave_id, :wavelet_id, :blip_id, :index, :property

  def initialize(op_type, wave_id, wavelet_id, blip_id='', index=-1,
               prop=nil)
    """Initializes this operation with contextual data.

    Args:
      op_type: Type of operation.
      wave_id: The id of the wave that this operation is to be applied.
      wavelet_id: The id of the wavelet that this operation is to be applied.
      blip_id: The optional id of the blip that this operation is to be applied.
      index: Optional integer index for content-based operations.
      prop: A weakly typed property object is based on the context of this
          operation.
    """
    self.type = op_type
    self.wave_id = wave_id
    self.wavelet_id = wavelet_id
    self.blip_id = blip_id
    self.index = index
    self.property = prop
  end
end

class OpBasedWave < Model::Wave
  """Subclass of the wave model capable of generating operations.

  Any mutation-based methods will likely result in one or more operations
  being applied locally and sent to the server.
  """

  def initialize(data, context)
    """Initializes this wave with the session context."""
    super(data)
    @__context = context
  end

  def CreateWavelet()
    """Creates a new wavelet on this wave."""
    @__context.builder.WaveletCreate(self.GetId())
  end
end

class OpBasedWavelet < Model::Wavelet
  """Subclass of the wavelet model capable of generating operations.

  Any mutation-based methods will likely result in one or more operations
  being applied locally and sent to the server.
  """

  def initialize(data, context)
    """Initializes this wavelet with the session context."""
    super(data)
    @__context = context
  end

  def CreateBlip()
    """Creates and appends a blip to this wavelet and returns it.

    Returns:
      A transient version of the blip that was created.
    """
    blip_data = @__context.builder.WaveletAppendBlip(self.GetWaveId(),
                                                         self.GetId())
    return @__context.AddBlip(blip_data)
  end

  def AddParticipant(participant_id)
    """Adds a participant to a wavelet.

    Args:
      participant_id: Id of the participant that is to be added.
    """
    @__context.builder.WaveletAddParticipant(self.GetWaveId(), self.GetId(),
                                                 participant_id)
    @_data.participants.push(participant_id) unless
      @_data.participants.include?(participant_id)
  end

  def RemoveSelf
    """Removes this robot from the wavelet."""
    @__context.builder.WaveletRemoveSelf(self.GetWaveId(), self.GetId())
    # TODO(davidbyttow): Locally remove the robot.
  end

  def SetDataDocument(name, data)
    """Sets a key/value pair on the wavelet data document.

    Args:
      name: The string key.
      data: The value associated with this key.
    """
    @__context.builder.WaveletSetDataDoc(self.GetWaveId(), self.GetId(),
                                             name, data)
    @_data.data_documents[name] = data
  end

  def SetTitle(title)
    """Sets the title of this wavelet.

    Args:
      title: String title to for this wave.
    """
    @__context.builder.WaveletSetTitle(self.GetWaveId(), self.GetId(),
                                           title)
    @__data.title = title
  end
end

class OpBasedBlip < Model::Blip
  """Subclass of the blip model capable of generating operations.

  Any mutation-based methods will likely result in one or more operations
  being applied locally and sent to the server.
  """
  attr_accessor :_data, :_document

  def initialize(data, context)
    """Initializes this blip with the session context."""
    super(data, OpBasedDocument.new(data, context))
    @__context = context
  end

  def CreateChild
    """Creates a child blip of this blip."""
    blip_data = @__context.builder.BlipCreateChild(self.GetWaveId(),
                                                       self.GetWaveletId(),
                                                       self.GetId())
    return @__context.AddBlip(blip_data)
  end

  def Delete
    """Deletes this blip from the wavelet."""
    @__context.builder.BlipDelete(self.GetWaveId(),
                                      self.GetWaveletId(),
                                      self.GetId())
    return @__context.RemoveBlip(self.GetId())
  end
end

class OpBasedDocument < Model::Document
  """Subclass of the document model capable of generating operations.

  Any mutation-based methods will likely result in one or more operations
  being applied locally and sent to the server.

  TODO(davidbyttow): Manage annotations and elements as content is updated.
  """

  def initialize(blip_data, context)
    """Initializes this document with its owning blip and session context."""
    super(blip_data)
    @__context = context
  end

  def HasAnnotation(name)
    """Determines if given named annotation is anywhere on this document.

    Args:
      name: The key name of the annotation.

    Returns:
      True if the annotation exists.
    """
    for annotation in @_blip_data.annotations
      if annotation.name == name
        return true
      end
    end
    return false
  end

  def SetText(text)
    """Clears and sets the text of this document.

    Args:
      text: The text content to replace this document with.
    """
    self.Clear()
    @__context.builder.DocumentInsert(@_blip_data.wave_id,
                                          @_blip_data.wavelet_id,
                                          @_blip_data.blip_id,
                                          text)
    @_blip_data.content = text
  end

  def SetTextInRange(r, text)
    """Deletes text within a range and sets the supplied text in its place.

    Args:
      r: Range to delete and where to set the new text.
      text: The text to set at the range start position.
    """
    self.DeleteRange(r)
    self.InsertText(r.first, text)
  end

  def InsertText(start, text)
    """Inserts text at a specific position.

    Args:
      start: The index position where to set the text.
      text: The text to set.
    """
    @__context.builder.DocumentInsert(@_blip_data.wave_id,
                                          @_blip_data.wavelet_id,
                                          @_blip_data.blip_id,
                                          text, index=start)
    left = @_blip_data.content[0...start]
    right = @_blip_data.content[start..-1]
    @_blip_data.content = left + text + right
  end

  def AppendText(text)
    """Appends text to the end of this document.

    Args:
      text: The text to append.
    """
    @__context.builder.DocumentAppend(@_blip_data.wave_id,
                                          @_blip_data.wavelet_id,
                                          @_blip_data.blip_id,
                                          text)
    @_blip_data.content += text
  end

  def Clear
    """Clears the content of this document."""
    @__context.builder.DocumentDelete(@_blip_data.wave_id,
                                          @_blip_data.wavelet_id,
                                          @_blip_data.blip_id,
                                          0, @_blip_data.content.length)
    @_blip_data.content = ''
  end

  def DeleteRange(r)
    """Deletes the content in the specified range.

    Args:
      r: A Range instance specifying the range to delete.
    """
    @__context.builder.DocumentDelete(@_blip_data.wave_id,
                                          @_blip_data.wavelet_id,
                                          @_blip_data.blip_id,
                                          r.first, r.end)
    left = @_blip_data.content[0...r.first]
    right = @_blip_data.content[r.end + 1..-1]
    @_blip_data.content = left + right
  end

  def AnnotateDocument(name, value)
    """Annotates the entire document.

    Args:
      name: A string as the key for this annotation.
      value: The value of this annotation.
    """
    b = @__context.builder
    b.DocumentAnnotationSetNoRange(@_blip_data.wave_id,
                                   @_blip_data.wavelet_id,
                                   @_blip_data.blip_id,
                                   name, value)
    r = Range.new(0, @_blip_data.content.length)
    @_blip_data.annotations.push(Annotation.new(name, value, r))
  end

  def SetAnnotation(r, name, value)
    """Sets an annotation on a given range.

    Args:
      r: A Range specifying the range to set the annotation.
      name: A string as the key for this annotation.
      value: The value of this annotaton.
    """
    @__context.builder.DocumentAnnotationSet(@_blip_data.wave_id,
                                                 @_blip_data.wavelet_id,
                                                 @_blip_data.blip_id,
                                                 r.first, r.end,
                                                 name, value)
    @_blip_data.annotations.push(Annotation.new(name, value, r))
  end

  def DeleteAnnotationsByName(name)
    """Deletes all annotations with a given key name.

    Args:
      name: A string as the key for the annotation to delete.
    """
    size = @_blip_data.content.length
    @__context.builder.DocumentAnnotationDelete(@_blip_data.wave_id,
                                                    @_blip_data.wavelet_id,
                                                    @_blip_data.blip_id,
                                                    0, size, name)
    for index in range(len(@_blip_data.annotations))
      annotation = @_blip_data.annotations[index]
      if annotation.name == name
        del @_blip_data.annotations[index]
      end
    end
  end

  def DeleteAnnotationsInRange(r, name)
    """Clears all of the annotations within a given range with a given key.

    Args:
      r: A Range specifying the range to delete.
      name: Annotation key type to clear.
    """
    @__context.builder.DocumentAnnotationDelete(@_blip_data.wave_id,
                                                    @_blip_data.wavelet_id,
                                                    @_blip_data.blip_id,
                                                    r.first, r.end,
                                                    name)
    # TODO(davidbyttow): split local annotations.
  end

  def AppendInlineBlip
    """Appends an inline blip to this blip.

    Returns:
      The local blip that was appended.
    """
    blip_data = @__context.builder.DocumentInlineBlipAppend(
        @_blip_data.wave_id, @_blip_data.wavelet_id,
        @_blip_data.blip_id)
    return @__context.AddBlip(blip_data)
  end

  def DeleteInlineBlip(inline_blip_id)
    """Deletes an inline blip from this blip.

    Args:
      inline_blip_id: The id of the blip to remove.
    """
    @__context.builder.DocumentInlineBlipDelete(@_blip_data.wave_id,
                                                    @_blip_data.wavelet_id,
                                                    @_blip_data.blip_id,
                                                    inline_blip_id)
    @__context.RemoveBlip(inline_blip_id)
  end

  def InsertInlineBlip(position)
    """Inserts an inline blip into this blip at a specific position.

    Args:
      position: Position to insert the blip at.

    Returns:
      The BlipData of the blip that was created.
    """
    blip_data = @__context.builder.DocumentInlineBlipInsert(
        @_blip_data.wave_id,
        @_blip_data.wavelet_id,
        @_blip_data.blip_id,
        position)
    # TODO(davidbyttow): Add local blip element.
    return @__context.AddBlip(blip_data)
  end

  def DeleteElement(position)
    """Deletes an Element at a given position.

    Args:
      position: Position of the Element to delete.
    """
    @__context.builder.DocumentElementDelete(@_blip_data.wave_id,
                                                 @_blip_data.wavelet_id,
                                                 @_blip_data.blip_id,
                                                 position)
  end

  def InsertElement(position, element)
    """Inserts an Element at a given position.

    Args:
      position: Position of the element to replace.
      element: The Element to replace with.
    """
    @__context.builder.DocumentElementInsert(@_blip_data.wave_id,
                                                 @_blip_data.wavelet_id,
                                                 @_blip_data.blip_id,
                                                 position, element)
  end

  def ReplaceElement(position, element)
    """Replaces an Element at a given position with a new element.

    Args:
      position: Position of the element to replace.
      element: The Element to replace with.
    """
    @__context.builder.DocumentElementReplace(@_blip_data.wave_id,
                                                  @_blip_data.wavelet_id,
                                                  @_blip_data.blip_id,
                                                  position, element)
  end

  def AppendElement(element)
    @__context.builder.DocumentElementAppend(@_blip_data.wave_id,
                                                 @_blip_data.wavelet_id,
                                                 @_blip_data.blip_id,
                                                 element)
  end
end

class ContextImpl_ < Model::Context
  """An internal implementation of the Context class.

  This implementation of the context is capable of adding waves, wavelets
  and blips to itself. This is useful when applying operations locally
  in a single session. Through this, clients can access waves, wavelets and
  blips and add operations to be applied to those objects by the server.

  Operations are applied in the order that they are received. Adding
  operations manually will not be reflected in the state of the context.
  """
  attr_reader :builder

  def initialize
    super
    @builder = OpBuilder.new(self)
  end

  def AddOperation(op)
    """Adds an operation to the list of operations to applied by the server.

    After all events are handled, the operation list is sent back to the server
    and applied in order. Adding an operation this way will have no effect
    on the state of the context or its entities.

    Args:
      op: An instance of an Operation.
    """
    @_operations.push(op)
  end

  def AddWave(wave_data)
    """Adds a transient wave based on the data supplied.

    Args:
      wave_data: An instance of WaveData describing this wave.

    Returns:
      An OpBasedWave that may have operations applied to it.
    """
    wave = OpBasedWave.new(wave_data, self)
    @_waves[wave.GetId()] = wave
    return wave
  end

  def AddWavelet(wavelet_data)
    """Adds a transient wavelet based on the data supplied.

    Args:
      wavelet_data: An instance of WaveletData describing this wavelet.

    Returns:
      An OpBasedWavelet that may have operations applied to it.
    """
    wavelet = OpBasedWavelet.new(wavelet_data, self)
    @_wavelets[wavelet.GetId()] = wavelet
    return wavelet
  end

  def AddBlip(blip_data)
    """Adds a transient blip based on the data supplied.

    Args:
      blip_data: An instance of BlipData describing this blip.

    Returns:
      An OpBasedBlip that may have operations applied to it.
    """
    blip = OpBasedBlip.new(blip_data, self)
    @_blips[blip.GetId()] = blip
    return blip
  end

  def RemoveWave(wave_id)
    """Removes a wave locally."""
    @_waves.delete wave_id
  end

  def RemoveWavelet(wavelet_id)
    """Removes a wavelet locally."""
    @_wavelets.delete wavelet_id
  end

  def RemoveBlip(blip_id)
    """Removes a blip locally."""
    @_blips.delete blip_id
  end

  def Serialize
    """Serialize the operation bundle.

    Returns:
      Dict representing this object.
    """
    data = {
        'javaClass' => 'com.google.wave.api.impl.OperationMessageBundle',
        'operations' => Util.Serialize(@_operations)
    }
    return data
  end
end

def CreateContext(data)
  """Creates a Context instance from raw data supplied by the server.

  Args:
    data: Raw data decoded from JSON sent by the server.

  Returns:
    A Context instance for this session.
  """
  context = ContextImpl_.new()
  data['blips'].values.map do |raw_blip|
    blip_data = Model.CreateBlipData(raw_blip)
    context.AddBlip(blip_data)
  end

  # Currently only one wavelet is sent.
  wavelet_data = Model.CreateWaveletData(data['wavelet'])
  context.AddWavelet(wavelet_data)

  # Waves are not sent over the wire, but we can build the list based on the
  # wave ids of the wavelets.
  wave_wavelet_map = {}
  wavelets = context.GetWavelets()
  for wavelet in wavelets:
    wave_id = wavelet.GetWaveId()
    wavelet_id = wavelet.GetId()
    if not wave_wavelet_map.include? wave_id
      wave_wavelet_map[wave_id] = []
    end
    wave_wavelet_map[wave_id].push(wavelet_id)
  end

  wave_wavelet_map.each_pair do |wave_id, wavelet_ids|
    wave_data = Model::WaveData.new()
    wave_data.id = wave_id
    wave_data.wavelet_ids = wavelet_ids
    context.AddWave(wave_data)
  end

  return context
end

class OpBuilder
  """Wraps all currently supportable operations as functions.

  The operation builder wraps single operations as functions and generates
  operations in-order on its context. This should only be used when the context
  is not available on a specific entity. For example, to modify a blip that
  does not exist in the current context, you might specify the wave, wavelet
  and blip id to generate an operation.

  Any calls to this will not reflect the local context state in any way.
  For example, calling WaveletAppendBlip will not result in a new blip
  being added to the local context, only an operation to be applied on the
  server.
  """

  def initialize(context)
    """Initializes the op builder with the context.

    Args:
      context: A Context instance to generate operations on.
    """
    @__context = context
  end

  def __CreateNewBlipData(wave_id, wavelet_id)
    """Creates an ephemeral BlipData instance used for this session."""
    blip_data = Model::BlipData.new()
    blip_data.wave_id = wave_id
    blip_data.wavelet_id = wavelet_id
    blip_data.blip_id = 'TBD_' + rand().to_s.split('.')[1]
    return blip_data
  end

  def WaveletAppendBlip(wave_id, wavelet_id)
    """Requests to append a blip to a wavelet.

    Args:
      wave_id: The wave id owning the containing wavelet.
      wavelet_id: The wavelet id that this blip should be appended to.

    Returns:
      A BlipData instance representing the id information of the new blip.
    """
    blip_data = __CreateNewBlipData(wave_id, wavelet_id)
    op = Operation.new(WAVELET_APPEND_BLIP, wave_id, wavelet_id, -1,
                   blip_data)
    @__context.AddOperation(op)
    return blip_data
  end

  def WaveletAddParticipant(wave_id, wavelet_id, participant_id)
    """Requests to add a participant to a wavelet.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      participant_id: Id of the participant to add.
    """
    op = Operation.new(WAVELET_ADD_PARTICIPANT, wave_id, wavelet_id, -1,
                   participant_id)
    @__context.AddOperation(op)
  end

  def WaveletCreate(wave_id)
    """Requests to create a wavelet in a wave.

    Not yet implemented.

    Args:
      wave_id: The wave id owning that this operation is applied to.

    Raises:
      NotImplementedError: Function not yet implemented.
    """
    raise NotImplementedError
  end

  def WaveletRemoveSelf(wave_id, wavelet_id)
    """Requests to remove this robot from a wavelet.

    Not yet implemented.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.

    Raises:
      NotImplementedError: Function not yet implemented.
    """
    raise NotImplementedError
  end

  def WaveletSetDataDoc(wave_id, wavelet_id, name, data)
    """Requests set a key/value pair on the data document of a wavelet.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      name: The key name for this data.
      data: The value of the data to set.
    """
    op = Operation.new(WAVELET_DATADOC_SET, wave_id, wavelet_id, name, -1,
                   data)
    @__context.AddOperation(op)
  end

  def WaveletSetTitle(wave_id, wavelet_id, title)
    """Requests to set the title of a wavelet.

    Not yet implemented.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      title: The title to set.

    Raises:
      NotImplementedError: Function not yet implemented.
    """
    raise NotImplementedError
  end

  def BlipCreateChild(wave_id, wavelet_id, blip_id)
    """Requests to create a child blip of another blip.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.

    Returns:
      BlipData instance for which further operations can be applied.
    """
    blip_data = __CreateNewBlipData(wave_id, wavelet_id)
    op = Operation.new(BLIP_CREATE_CHILD, wave_id, wavelet_id,
                   blip_id, -1, blip_data)
    @__context.AddOperation(op)
    return blip_data
  end

  def BlipDelete(wave_id, wavelet_id, blip_id)
    """Requests to delete (tombstone) a blip.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
    """
    op = Operation.new(BLIP_DELETE, wave_id, wavelet_id, :blip_id=>blip_id)
    @__context.AddOperation(op)
  end

  def DocumentAnnotationDelete(wave_id, wavelet_id, blip_id, start, _end,
                               name)
    """Deletes a specified annotation of a given range with a specific key.

    Not yet implemented.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      start: Start position of the range.
      _end: End position of the range.
      name: Annotation key name to clear.

    Raises:
      NotImplementedError: Function not yet implemented.
    """
    raise NotImplementedError
  end

  def DocumentAnnotationSet(wave_id, wavelet_id, blip_id, start, _end,
                            name, value)
    """Set a specified annotation of a given range with a specific key.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      start: Start position of the range.
      end: End position of the range.
      name: Annotation key name to clear.
      value: The value of the annotation across this range.
    """
    annotation = Annotation.new(name, value, Range.new(start, _end))
    op = Operation.new(DOCUMENT_ANNOTATION_SET, wave_id, wavelet_id,
                   blip_id, -1, annotation)
    @__context.AddOperation(op)
  end

  def DocumentAnnotationSetNoRange(wave_id, wavelet_id, blip_id,
                                   name, value)
    """Requests to set an annotation on an entire document.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      name: Annotation key name to clear.
      value: The value of the annotation.
    """
    annotation = Annotation.new(name, value, nil)
    op = Operation.new(DOCUMENT_ANNOTATION_SET_NORANGE, wave_id, wavelet_id,
                       blip_id, -1, annotation)
    @__context.AddOperation(op)
  end

  def DocumentAppend(wave_id, wavelet_id, blip_id, content)
    """Requests to append content to a document.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      content: The content to append.
    """
    op = Operation.new(DOCUMENT_APPEND, wave_id, wavelet_id, blip_id,
                   -1, content)
    @__context.AddOperation(op)
  end

  def DocumentAppendStyledText(wave_id, wavelet_id, blip_id, text, style)
    """Requests to append styled text to the document.

    Not yet implemented.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      text: The text ot append..
      style: The style to apply.

    Raises:
      NotImplementedError: Function not yet implemented.
    """
    raise NotImplementedError
  end

  def DocumentDelete(wave_id, wavelet_id, blip_id, start, _end)
    """Requests to delete content in a given range.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      start: Start of the range.
      end: End of the range.
    """
    range = nil
    if start != _end
      range = Range.new(start, _end)
    end
    op = Operation.new(DOCUMENT_DELETE, wave_id, wavelet_id, blip_id, -1,
                       range)
    @__context.AddOperation(op)
  end

  def DocumentInsert(wave_id, wavelet_id, blip_id, content, index=0)
    """Requests to insert content into a document at a specific location.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      content: The content to insert.
      index: The position insert the content at in ths document.
    """
    op = Operation.new(DOCUMENT_INSERT, wave_id, wavelet_id, blip_id,
                       index, content)
    @__context.AddOperation(op)
  end

  def DocumentReplace(wave_id, wavelet_id, blip_id, content)
    """Requests to replace all content in a document.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      content: Content that will replace the current document.
    """
    op = Operation(DOCUMENT_REPLACE, wave_id, wavelet_id, blip_id,
                   prop=content)
    @__context.AddOperation(op)
  end

  def DocumentElementAppend(wave_id, wavelet_id, blip_id, element)
    """Requests to append an element to the document.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      element: Element instance to append.
    """
    op = Operation.new(DOCUMENT_ELEMENT_APPEND, wave_id, wavelet_id, blip_id,
                   -1, element)
    @__context.AddOperation(op)
  end

  def DocumentElementDelete(wave_id, wavelet_id, blip_id, position)
    """Requests to delete an element from the document at a specific position.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      position: Position of the element to delete.
    """
    op = Operation(DOCUMENT_ELEMENT_DELETE, wave_id, wavelet_id, blip_id,
                   index=position)
    @__context.AddOperation(op)
  end

  def DocumentElementInsert(wave_id, wavelet_id, blip_id, position,
                            element)
    """Requests to insert an element to the document at a specific position.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      position: Position of the element to delete.
      element: Element instance to insert.
    """
    op = Operation(DOCUMENT_ELEMENT_INSERT, wave_id, wavelet_id, blip_id,
                   index=position,
                   prop=element)
    @__context.AddOperation(op)
  end

  def DocumentElementInsertAfter
    """Requests to insert an element after the specified location.

    Not yet implemented.

    Raises:
      NotImplementedError: Function not yet implemented.
    """
    raise NotImplementedError
  end

  def DocumentElementInsertBefore
    """Requests to insert an element before the specified location.

    Not yet implemented.

    Raises:
      NotImplementedError: Function not yet implemented.
    """
    raise NotImplementedError
  end

  def DocumentElementReplace(wave_id, wavelet_id, blip_id, position,
                             element)
    """Requests to replace an element.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      position: Position of the element to replace.
      element: Element instance to replace.
    """
    op = Operation(DOCUMENT_ELEMENT_REPLACE, wave_id, wavelet_id, blip_id,
                   index=position,
                   prop=element)
    @__context.AddOperation(op)
  end

  def DocumentInlineBlipAppend(wave_id, wavelet_id, blip_id)
    """Requests to create and append a new inline blip to another blip.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.

    Returns:
      A BlipData instance containing the id information.
    """
    inline_blip_data = __CreateNewBlipData(wave_id, wavelet_id)
    op = Operation.new(DOCUMENT_INLINE_BLIP_APPEND, wave_id, wavelet_id,
                   blip_id, -1, inline_blip_data)
    @__context.AddOperation(op)
    inline_blip_data.parent_blip_id = blip_id
    return inline_blip_data
  end

  def DocumentInlineBlipDelete(wave_id, wavelet_id, blip_id,
                               inline_blip_id)
    """Requests to delete an inline blip from its parent.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      inline_blip_id: The blip to be deleted.
    """
    op = Operation.new(DOCUMENT_INLINE_BLIP_DELETE, wave_id, wavelet_id,
                       blip_id, -1, inline_blip_id)
    @__context.AddOperation(op)
  end

  def DocumentInlineBlipInsert(wave_id, wavelet_id, blip_id, position)
    """Requests to insert an inline blip at a specific location.

    Args:
      wave_id: The wave id owning that this operation is applied to.
      wavelet_id: The wavelet id that this operation is applied to.
      blip_id: The blip id that this operation is applied to.
      position: The position in the document to insert the blip.

    Returns:
      BlipData for the blip that was created for further operations.
    """
    inline_blip_data = __CreateNewBlipData(wave_id, wavelet_id)
    inline_blip_data.parent_blip_id = blip_id
    op = Operation.new(DOCUMENT_INLINE_BLIP_INSERT, wave_id, wavelet_id,
                   blip_id, position, inline_blip_data)
    @__context.AddOperation(op)
    return inline_blip_data
  end

  def DocumentInlineBlipInsertAfterElement
    """Requests to insert an inline blip after an element.

    Raises:
      NotImplementedError: Function not yet implemented.
    """
    raise NotImplementedError
  end
end
