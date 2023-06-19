//import com.sun.jna.*;
//import com.sun.jna.Library;
//import com.sun.jna.Native;
//import com.sun.jna.NativeLibrary;
//import com.sun.jna.Pointer;
//import com.sun.jna.ptr.IntByReference;
//import com.sun.jna.ptr.ShortByReference;
//import com.sun.jna.Structure;
//import com.sun.jna.Structure.FieldOrder;

import java.nio.ByteBuffer;
import java.nio.IntBuffer;
import java.nio.ShortBuffer;

public static class MyCAENDigitizer implements Library {
  public static final String JNA_LIBRARY_NAME = "MyCAENDigitizer";

  public static final NativeLibrary JNA_NATIVE_LIB = NativeLibrary.getInstance("CAENDigitizer");

  public static native int CAEN_DGTZ_OpenDigitizer(int LinkType, int LinkNum, int ConetNode, int VMEBaseAddress, IntBuffer handleIB);
  public static native int CAEN_DGTZ_OpenDigitizer(int LinkType, int LinkNum, int ConetNode, int VMEBaseAddress, int[] handle);  // also works with int array

  public static native int CAEN_DGTZ_OpenDigitizer2(int LinkType, IntBuffer LinkNumIB, int ConetNode, int VMEBaseAddress, IntBuffer handleIB);
  public static native int CAEN_DGTZ_OpenDigitizer2(int LinkType, IntByReference LinkNumIB, int ConetNode, int VMEBaseAddress, IntBuffer handleIB);

  public static native int CAEN_DGTZ_CloseDigitizer(int handle);

  public static native int CAEN_DGTZ_ReadTemperature(int handle, int ch, IntBuffer tempIB);

  public static native int CAEN_DGTZ_SetChannelEnableMask(int handle, int mask);
  public static native int CAEN_DGTZ_GetChannelEnableMask(int handle, IntBuffer maskIB);

  public static native int CAEN_DGTZ_SetGroupEnableMask(int handle, int mask);
  public static native int CAEN_DGTZ_GetGroupEnableMask(int handle, IntBuffer maskIB);

  public static native int CAEN_DGTZ_SetAcquisitionMode(int handle, int mode);
  public static native int CAEN_DGTZ_GetAcquisitionMode(int handle, IntBuffer modeIB);

  public static native int CAEN_DGTZ_SetIOLevel(int handle, int level);
  public static native int CAEN_DGTZ_GetIOLevel(int handle, IntBuffer levelIB);

  public static native int CAEN_DGTZ_GetInfo(int handle, ByteBuffer paramByteBuffer);
  public static native int CAEN_DGTZ_GetInfo(int handle, CAEN_DGTZ_BoardInfo_t b);

  public static native int CAEN_DGTZ_SetMaxNumEventsBLT(int handle, int numEvents);
  public static native int CAEN_DGTZ_GetMaxNumEventsBLT(int handle, IntBuffer numEventsIB);

  public static native int CAEN_DGTZ_Reset(int handle);

  public static native int CAEN_DGTZ_SetRecordLength(int handle, int size);
  public static native int CAEN_DGTZ_GetRecordLength(int handle, IntBuffer sizeIB);

  public static native int CAEN_DGTZ_SetChannelTriggerThreshold(int handle, int channel, int tValue);
  public static native int CAEN_DGTZ_GetChannelTriggerThreshold(int handle, int channel, IntBuffer tValueIB);

  public static native int CAEN_DGTZ_SetTriggerPolarity(int handle, int channel, int trigPol);
  public static native int CAEN_DGTZ_GetTriggerPolarity(int handle, int channel, IntBuffer trigPolIB);

  public static native int CAEN_DGTZ_SetChannelPulsePolarity(int handle, int channel, int pulsePol);
  public static native int CAEN_DGTZ_GetChannelPulsePolarity(int handle, int channel, IntBuffer pulsePolIB);

  public static native int CAEN_DGTZ_SetChannelDCOffset(int handle, int channel, int tValue);
  public static native int CAEN_DGTZ_GetChannelDCOffset(int handle, int channel, IntBuffer tValueIB);

  public static native int CAEN_DGTZ_SetChannelSelfTrigger(int handle, int mode, int channelmask);
  public static native int CAEN_DGTZ_GetChannelSelfTrigger(int handle, int channel, IntBuffer modeIB);

  public static native int CAEN_DGTZ_SetSWTriggerMode(int handle, int mode);
  public static native int CAEN_DGTZ_GetSWTriggerMode(int handle, IntBuffer modeIB);

  public static native int CAEN_DGTZ_MallocReadoutBuffer(int handle, PointerByReference refToBufferPointer, IntBuffer sizeIB);
  public static native int CAEN_DGTZ_FreeReadoutBuffer(PointerByReference refToBufferPointer);

  public static native int CAEN_DGTZ_SWStartAcquisition(int handle);
  public static native int CAEN_DGTZ_SWStopAcquisition(int handle);

  public static native  int CAEN_DGTZ_SendSWtrigger(int handle);

  public static native  int CAEN_DGTZ_ClearData(int handle);

  public static native  int CAEN_DGTZ_ReadData(int handle, int mode, Pointer bufferPointer, IntBuffer bufferSizeIB);

  public static native  int CAEN_DGTZ_GetNumEvents(int handle, Pointer bufferPointer, int buffsize, IntBuffer numEventsIB);

  public static native  int CAEN_DGTZ_GetEventInfo(int handle, Pointer bufferPointer, int buffsize, int eventIndex, EventInfo_t eventInfo, PointerByReference refToEventPointer);

  //public static native  int CAEN_DGTZ_DecodeEvent(int handle, Pointer eventPointer, CAEN_DGTZ_UINT16_EVENT_t eventStruct);
  public static native  int CAEN_DGTZ_DecodeEvent(int handle, Pointer eventPointer, PointerByReference refToEventStructPointer);
  //public static native  int CAEN_DGTZ_DecodeEvent(int handle, Pointer eventPointer, Pointer eventStructPointer);

  public static native  int CAEN_DGTZ_AllocateEvent(int handle, PointerByReference refToEventStructPointer);
  public static native  int CAEN_DGTZ_FreeEvent(int handle, PointerByReference refToEventStructPointer);

  public static native  int CAEN_DGTZ_WriteRegister(int handle, int address, int data);
  public static native  int CAEN_DGTZ_ReadRegister(int handle, int address, IntBuffer dataIB);

  public static native int CAEN_DGTZ_SetPostTriggerSize(int handle, int percent);
  public static native int CAEN_DGTZ_GetPostTriggerSize(int handle, IntBuffer percentIB);

  public static native int CAEN_DGTZ_SetSAMPostTriggerSize(int handle, int SamIndex, int value);
  public static native int CAEN_DGTZ_GetSAMPostTriggerSize(int handle, int SamIndex, IntBuffer valueIB);

  public static native int CAEN_DGTZ_SetSAMSamplingFrequency(int handle, int frequency);
  public static native int CAEN_DGTZ_GetSAMSamplingFrequency(int handle, IntBuffer frequencyIB);

  public static native int CAEN_DGTZ_SetSAMAcquisitionMode(int boardHandle, int mode);
  public static native int CAEN_DGTZ_GetSAMAcquisitionMode(int handle, IntBuffer modeIB);


  public static native int CAEN_DGTZ_SetChannelPairTriggerLogic(int boardHandle, int channelA, int channelB, int logic, short coincidenceWindow);
  public static native int CAEN_DGTZ_GetChannelPairTriggerLogic(int boardHandle, int channelA, int channelB, IntBuffer logicIB, ShortBuffer coincidenceWindowSB);

  public static native int CAEN_DGTZ_SetTriggerLogic(int boardHandle, int logic, int majorityLevel);
  public static native int CAEN_DGTZ_GetTriggerLogic(int boardHandle, IntBuffer logicIB, IntBuffer majorityLevelIB);



  static {
    Native.register(JNA_NATIVE_LIB);  // e nelkul nem megy, nem tudom, miert, de a CAENComm-ban is megvan
  }
}  // public static class MyCAENDigitizer implements Library {



////////////////////////// mapping C enums /////////////////////////////////////////////////////////////////
public static interface CAENDigitizer_ConnectionType {
  public static final int CAENDigitizer_USB = 0;
  public static final int CAENDigitizer_OpticalLink = 1;
}

public static interface TriggerPolarity_t {
  public static final int TriggerOnRisingEdge = 0;
  public static final int TriggerOnFallingEdge = 1;
}

public static interface PulsePolarity_t {
  public static final int pulsePolarityPos = 0;
  public static final int pulsePolarityNeg = 1;
}

public static interface AcqMode_t {
  public static final int SW_CONTROLLED = (int)0;
  public static final int S_IN_CONTROLLED = (int)1;
  public static final int FIRST_TRG_CONTROLLED = (int)2;
  public static final int LVDS_CONTROLLED = (int)3;
};

public static interface TriggerMode_t {
  public static final int CAEN_DGTZ_TRGMODE_DISABLED = (int)0;
  public static final int CAEN_DGTZ_TRGMODE_EXTOUT_ONLY = (int)2;
  public static final int CAEN_DGTZ_TRGMODE_ACQ_ONLY = (int)1;
  public static final int CAEN_DGTZ_TRGMODE_ACQ_AND_EXTOUT = (int)3;
};

public static interface CAEN_DGTZ_ReadMode_t {
  public static final int CAEN_DGTZ_SLAVE_TERMINATED_READOUT_MBLT = (int)0;
  public static final int CAEN_DGTZ_SLAVE_TERMINATED_READOUT_2eVME = (int)1;
  public static final int CAEN_DGTZ_SLAVE_TERMINATED_READOUT_2eSST = (int)2;
  public static final int CAEN_DGTZ_POLLING_MBLT = (int)3;
  public static final int CAEN_DGTZ_POLLING_2eVME = (int)4;
  public static final int CAEN_DGTZ_POLLING_2eSST = (int)5;
};

public static interface SAMFrequency_t {
  public static final int CAEN_DGTZ_SAM_3_2GHz = 0;
  public static final int CAEN_DGTZ_SAM_1_6GHz = 1;
  public static final int CAEN_DGTZ_SAM_800MHz = 2;
  public static final int CAEN_DGTZ_SAM_400MHz = 3;
}

public static interface SAMAcquisitionMode_t {
  public static final int CAEN_DGTZ_AcquisitionMode_STANDARD = 0;   //Digital oscilloscope mode
  public static final int CAEN_DGTZ_AcquisitionMode_DPP_CI = 1;  //Charge integration mode – charge data are expressed in pC
}

public static interface TriggerLogic_t {
  public static final int CAEN_DGTZ_LOGIC_OR = 0;   //The trigger is the OR of the self-trigger signals from the pair
  public static final int CAEN_DGTZ_LOGIC_AND = 1;  //The trigger is the AND of the self-trigger signals from the pair
  public static final int CAEN_DGTZ_LOGIC_MAJORITY = 2 ;  //
}


///////////////////////// mapping C structures ////////////////////////////////////////
@Structure.FieldOrder( {
  "ModelName", "Model", "Channels", "FormFactor", "FamilyCode", "ROC_FirmwareRel", "AMC_FirmwareRel", "SerialNumber", "MezzanineSerNum", "PCB_Revision", "ADC_NBits", "SAMCorrectionDataLoaded", "CommHandle", "VMEHandle", "License"
}
)
public class CAEN_DGTZ_BoardInfo_t extends Structure {
  /// C type : char[12]
  public byte[] ModelName = new byte[(12)];
  public int Model;
  public int Channels;
  public int FormFactor;
  public int FamilyCode;
  /// C type : char[20]
  public byte[] ROC_FirmwareRel = new byte[(20)];
  /// C type : char[40]
  public byte[] AMC_FirmwareRel = new byte[(40)];
  public int SerialNumber;
  /**
   * used only for x743 boards<br>
   * C type : char[4][8]
   */
  public byte[] MezzanineSerNum = new byte[4 * 8];
  public int PCB_Revision;
  public int ADC_NBits;
  /// used only for x743 boards
  public int SAMCorrectionDataLoaded;
  public int CommHandle;
  public int VMEHandle;
  /// C type : char[((8) * 2 + 1)]
  public byte[] License = new byte[((8) * 2 + 1)];
}



@Structure.FieldOrder( {
  "eventSize", "boardId", "pattern", "channelMask", "eventCounter", "triggerTimeTag"
}
)
public class EventInfo_t extends Structure {
  public int eventSize;
  public int boardId;
  public int pattern;
  public int channelMask;
  public int eventCounter;
  public int triggerTimeTag;
}



@Structure.FieldOrder( {
  "ChSize", "DataChannel"
}
)
public class UINT16_EVENT_t extends Structure {
  public int[] ChSize = new int[(64)];  // the number of samples stored in DataChannel array
  //public ShortByReference[] DataChannel = new ShortByReference[(64)];
  public Pointer[] DataChannel = new Pointer[(64)];

  public UINT16_EVENT_t() {
    super();
  }

  public UINT16_EVENT_t(Pointer pointer) {
    super(pointer);
    read();  // enelkul nem megy!
  }
}


final int MAX_X743_CHANNELS_X_GROUP = 2;
@Structure.FieldOrder( {
  "ChSize", "DataChannel", "TriggerCount", "TimeCount", "EventId", "StartIndexCell", "TDC", "PosEdgeTimeStamp", "NegEdgeTimeStamp", "PeakIndex", "Peak", "Baseline", "Charge"
}
)
public class CAEN_DGTZ_X743_GROUP_t extends Structure {
  public int ChSize;  // the number of samples stored in DataChannel array
  public Pointer[] DataChannel = new Pointer[MAX_X743_CHANNELS_X_GROUP];  // the float !!! array of ChSize samples
  public short[] TriggerCount = new short[MAX_X743_CHANNELS_X_GROUP];
  public short[] TimeCount = new short[MAX_X743_CHANNELS_X_GROUP];
  public byte EventId;
  public short StartIndexCell;
  public long TDC;
  public float PosEdgeTimeStamp;
  public float NegEdgeTimeStamp;
  public short PeakIndex;
  public float Peak;
  public float Baseline;
  public float Charge;

  public CAEN_DGTZ_X743_GROUP_t() {
    super();
  }

  public CAEN_DGTZ_X743_GROUP_t(Pointer pointer) {
    super(pointer);
    //read();  // enelkul nem megy!
  }
}


final int MAX_V1743_GROUP_SIZE = 8;
@Structure.FieldOrder( {
  "GrPresent", "DataGroup"
}
)
public class CAEN_DGTZ_X743_EVENT_t extends Structure {
  public byte[] GrPresent = new byte[MAX_V1743_GROUP_SIZE];
  public CAEN_DGTZ_X743_GROUP_t[] DataGroup =  new CAEN_DGTZ_X743_GROUP_t[MAX_V1743_GROUP_SIZE];
  //public CAEN_DGTZ_X743_GROUP_t[] DataGroup = (CAEN_DGTZ_X743_GROUP_t[]) new CAEN_DGTZ_X743_GROUP_t().toArray(MAX_V1743_GROUP_SIZE);

  public CAEN_DGTZ_X743_EVENT_t() {
    super();
    for (int i = 0; i < MAX_V1743_GROUP_SIZE; i++) {
      DataGroup[i] = new CAEN_DGTZ_X743_GROUP_t();
    }
  }

  public CAEN_DGTZ_X743_EVENT_t(Pointer pointer) {
    super(pointer);
    //read();  // enelkul nem megy!
    for (int i = 0; i < MAX_V1743_GROUP_SIZE; i++) {
      DataGroup[i] = new CAEN_DGTZ_X743_GROUP_t(pointer);
    }
  }
}


@Structure.FieldOrder( {
  "GrPresent",  // If the group has data the value is 1 otherwise 0  
    "ChSize01", "DataChannel01", "TriggerCount01", "TimeCount01", "EventId01", "StartIndexCell01", "TDC01", "PosEdgeTimeStamp01", "NegEdgeTimeStamp01", "PeakIndex01", "Peak01", "Baseline01", "Charge01",
    "ChSize23", "DataChannel23", "TriggerCount23", "TimeCount23", "EventId23", "StartIndexCell23", "TDC23", "PosEdgeTimeStamp23", "NegEdgeTimeStamp23", "PeakIndex23", "Peak23", "Baseline23", "Charge23",
    "ChSize45", "DataChannel45", "TriggerCount45", "TimeCount45", "EventId45", "StartIndexCell45", "TDC45", "PosEdgeTimeStamp45", "NegEdgeTimeStamp45", "PeakIndex45", "Peak45", "Baseline45", "Charge45",
    "ChSize67", "DataChannel67", "TriggerCount67", "TimeCount67", "EventId67", "StartIndexCell67", "TDC67", "PosEdgeTimeStamp67", "NegEdgeTimeStamp67", "PeakIndex67", "Peak67", "Baseline67", "Charge67"
}
)
public class CAEN_DGTZ_X743_EVENT1_t extends Structure {
  public byte[] GrPresent = new byte[MAX_V1743_GROUP_SIZE];  // If the group has data the value is 1 otherwise 0  
  // samIndex 0
  public int ChSize01;  // the number of samples stored in DataChannel array
  public Pointer[] DataChannel01 = new Pointer[MAX_X743_CHANNELS_X_GROUP];  // the float !!! array of ChSize samples
  public short[] TriggerCount01 = new short[MAX_X743_CHANNELS_X_GROUP];
  public short[] TimeCount01 = new short[MAX_X743_CHANNELS_X_GROUP];
  public byte EventId01;
  public short StartIndexCell01;
  public long TDC01;
  public float PosEdgeTimeStamp01;
  public float NegEdgeTimeStamp01;
  public short PeakIndex01;
  public float Peak01;
  public float Baseline01;
  public float Charge01;
  //samIndex 1
  public int ChSize23;  // the number of samples stored in DataChannel array
  public Pointer[] DataChannel23 = new Pointer[MAX_X743_CHANNELS_X_GROUP];  // the float !!! array of ChSize samples
  public short[] TriggerCount23 = new short[MAX_X743_CHANNELS_X_GROUP];
  public short[] TimeCount23 = new short[MAX_X743_CHANNELS_X_GROUP];
  public byte EventId23;
  public short StartIndexCell23;
  public long TDC23;
  public float PosEdgeTimeStamp23;
  public float NegEdgeTimeStamp23;
  public short PeakIndex23;
  public float Peak23;
  public float Baseline23;
  public float Charge23;
  //samIndex 2
  public int ChSize45;  // the number of samples stored in DataChannel array
  public Pointer[] DataChannel45 = new Pointer[MAX_X743_CHANNELS_X_GROUP];  // the float !!! array of ChSize samples
  public short[] TriggerCount45 = new short[MAX_X743_CHANNELS_X_GROUP];
  public short[] TimeCount45 = new short[MAX_X743_CHANNELS_X_GROUP];
  public byte EventId45;
  public short StartIndexCell45;
  public long TDC45;
  public float PosEdgeTimeStamp45;
  public float NegEdgeTimeStamp45;
  public short PeakIndex45;
  public float Peak45;
  public float Baseline45;
  public float Charge45;
  //samIndex 3
  public int ChSize67;  // the number of samples stored in DataChannel array
  public Pointer[] DataChannel67 = new Pointer[MAX_X743_CHANNELS_X_GROUP];  // the float !!! array of ChSize samples
  public short[] TriggerCount67 = new short[MAX_X743_CHANNELS_X_GROUP];
  public short[] TimeCount67 = new short[MAX_X743_CHANNELS_X_GROUP];
  public byte EventId67;
  public short StartIndexCell67;
  public long TDC67;
  public float PosEdgeTimeStamp67;
  public float NegEdgeTimeStamp67;
  public short PeakIndex67;
  public float Peak67;
  public float Baseline67;
  public float Charge67;

  public CAEN_DGTZ_X743_EVENT1_t() {
    super();
    //  for (int i = 0; i < MAX_V1743_GROUP_SIZE; i++) {
    //    DataGroup[i] = new CAEN_DGTZ_X743_GROUP_t();
    //  }
  }

  public CAEN_DGTZ_X743_EVENT1_t(Pointer pointer) {
    super(pointer);
    read();  // enelkul nem megy!
    //  for (int i = 0; i < MAX_V1743_GROUP_SIZE; i++) {
    //    DataGroup[i] = new CAEN_DGTZ_X743_GROUP_t(pointer);
    //  }
  }
}


//my functions//////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
boolean openDevice(int linkNum, int address) {
  IntBuffer handleIB = IntBuffer.allocate(1);
  //int[] handle = new int[1];  // also works with int array
  //int type = 0;
  int linkType = CAENDigitizer_ConnectionType.CAENDigitizer_USB;
  //int linkNum = 0;
  int conetNode = 0;
  int err = MyCAENDigitizer.CAEN_DGTZ_OpenDigitizer(linkType, linkNum, conetNode, unhex( str(address) ), handleIB);
  if ( noError(err) ) {
    println("Connected");
    consolFile.println("Connected");
    boardHandle = handleIB.get(0);
    //boardHandle = handle[0];  // also works with int array
  }
  return (err == 0);
}


////////////////////////////////////////////////////////////////////////////////
boolean openDevice2(int linkNum, int address) {
  IntBuffer handleIB = IntBuffer.allocate(1);
  IntBuffer linkNumIB = IntBuffer.allocate(1);
  IntByReference linkNumIBR = new IntByReference(1);
  //int[] handle = new int[1];  // also works with int array
  //int type = 0;
  int linkType = CAENDigitizer_ConnectionType.CAENDigitizer_USB;
  //int linkNum = 0;
  //linkNumIB.put(linkNum);
  linkNumIBR.setValue(linkNum);
  int conetNode = 0;
  //int err = MyCAENDigitizer.CAEN_DGTZ_OpenDigitizer2(linkType, linkNumIB, conetNode, unhex( str(address) ), handleIB);
  int err = MyCAENDigitizer.CAEN_DGTZ_OpenDigitizer2(linkType, linkNumIBR, conetNode, unhex( str(address) ), handleIB);
  if ( noError(err) ) {
    println("Connected");
    consolFile.println("Connected");
    boardHandle = handleIB.get(0);
    //boardHandle = handle[0];  // also works with int array
  }
  return (err == 0);
}


////////////////////////////////////////////////////////////////////////////////
//void getInfo() {
//  ByteBuffer bb = ByteBuffer.allocate(160);
//  int err = MyCAENDigitizer.CAEN_DGTZ_GetInfo(boardHandle, bb);
//  if ( noError(err) ) {
//    byte [] ba = bb.array();
//    //println( "bb: " + new String( ba ) );  // igy lesz a bajtokbol szoveg
//    String hexString = "";
//    //for (byte b : ba) {
//    //  hexString += hex(b);
//    //}

//    for (int i=0; i<ba.length; i++) {
//      if ( i > 127 ) hexString += hex(ba[i]);  // csak az utolso 33 bajtot irom ki
//      int ib = int(ba[i]);
//      if ( ib < 32 || ib > 127) ba[i] = 1;
//    }
//    println( "bb = 0x" + hexString );  // igy lesz a bajtokbol hex
//    println( "bb: " + new String( ba ) );  // igy lesz a bajtokbol szoveg
//  }
//  //MyCAENDigitizer.BoardInfo boardInfo;
//  //err = MyCAENDigitizer.CAEN_DGTZ_GetInfo(boardHandle, boardInfo);
//}


////////////////////////////////////////////////////////////////////////////////
CAEN_DGTZ_BoardInfo_t getInfo() {
  CAEN_DGTZ_BoardInfo_t boardInfoStruct = new CAEN_DGTZ_BoardInfo_t();
  int err = MyCAENDigitizer.CAEN_DGTZ_GetInfo(boardHandle, boardInfoStruct);
  if ( noError(err) ) {
    println( "Connected to CAEN Digitizer Model " + new String(boardInfoStruct.ModelName) + ", serial number " + boardInfoStruct.SerialNumber );
    println( "\t" + boardInfoStruct.Channels + " channels, " + boardInfoStruct.ADC_NBits + " bits" );
    println( "\tROC FPGA Release is " + new String(boardInfoStruct.ROC_FirmwareRel) );
    println("\tAMC FPGA Release is " + new String(boardInfoStruct.AMC_FirmwareRel) );
    consolFile.println( "Connected to CAEN Digitizer Model " + new String(boardInfoStruct.ModelName) + ", serial number " + boardInfoStruct.SerialNumber );
    consolFile.println( "\t" + boardInfoStruct.Channels + " channels, " + boardInfoStruct.ADC_NBits + " bits" );
    consolFile.println( "\tROC FPGA Release is " + new String(boardInfoStruct.ROC_FirmwareRel) );
    consolFile.println("\tAMC FPGA Release is " + new String(boardInfoStruct.AMC_FirmwareRel) );
    return boardInfoStruct;
  } else return null;
}


////////////////////////////////////////////////////////////////////////////////
void readTemperature(int ch) {
  IntBuffer tempIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_ReadTemperature(boardHandle, ch, tempIB);
  if ( noError(err) ) {
    println("Ch" + ch + " temperature read from board: " + tempIB.get(0) + " °C");
    consolFile.println("Ch" + ch + " temperature read from board: " + tempIB.get(0) + " °C");
  }
}


////////////////////////////////////////////////////////////////////////////////
void setAcquisitionMode(int mode) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetAcquisitionMode(boardHandle, mode);
  if ( noError(err) ) {
    println( "Acquisition Mode set to " + mode );
    consolFile.println( "Acquisition Mode set to " + mode );
  }
}

void getAcquisitionMode() {
  IntBuffer modeIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetAcquisitionMode(boardHandle, modeIB);
  if ( noError(err) ) {
    println( "Acquisition Mode read from board: " + modeIB.get(0) );
    consolFile.println( "Acquisition Mode read from board: " + modeIB.get(0) );
  }
}


////////////////////////////////////////////////////////////////////////////////
void setIOLevel(int level) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetIOLevel(boardHandle, level);
  if ( noError(err) ) {
  }
}

void getIOLevel() {
  IntBuffer levelIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetIOLevel(boardHandle, levelIB);
  if ( noError(err) ) {
    println( "IO level read from board: " + levelIB.get(0) );
    consolFile.println( "IO level read from board: " + levelIB.get(0) );
  }
}


////////////////////////////////////////////////////////////////////////////////
void setChannelTriggerPolarity(int channel, int trigPol) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetTriggerPolarity(boardHandle, channel, trigPol);
  if ( noError(err) ) {
    println( "ch" + channel + " trigger polarity set to " + trigPol );
    consolFile.println( "ch" + channel + " trigger polarity set to " + trigPol );
  }
}

void getChannelTriggerPolarity(int channel) {
  IntBuffer trigPolIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetTriggerPolarity(boardHandle, channel, trigPolIB);
  if ( noError(err) ) {
    println( "ch" + channel + " trigger polarity read from board: " + trigPolIB.get(0) );
    consolFile.println( "ch" + channel + " trigger polarity read from board: " + trigPolIB.get(0) );
  }
}


////////////////////////////////////////////////////////////////////////////////
void setChannelPulsePolarity(int channel, int pulsePol) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetChannelPulsePolarity(boardHandle, channel, pulsePol);
  if ( noError(err) ) {
  }
}

int getChannelPulsePolarity(int channel) {
  IntBuffer pulsePolIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetChannelPulsePolarity(boardHandle, channel, pulsePolIB);
  if ( noError(err) ) {
    println( "ch" + channel + " pulse polarity read from board: " + pulsePolIB.get(0) );
    consolFile.println( "ch" + channel + " pulse polarity read from board: " + pulsePolIB.get(0) );
    return pulsePolIB.get(0);
  } else return -1;
}


////////////////////////////////////////////////////////////////////////////////
void setMaxNumEventsBLT(int maxNumEvents) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetMaxNumEventsBLT(boardHandle, maxNumEvents);
  if ( noError(err) ) {
    println( "maxNumEvents set to " + maxNumEvents + " for each block transfer" );
    consolFile.println( "maxNumEvents set to " + maxNumEvents + " for each block transfer" );
  }
}

void getMaxNumEventsBLT() {
  IntBuffer maxNumEventsIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetMaxNumEventsBLT(boardHandle, maxNumEventsIB);
  if ( noError(err) ) {
    println( "maxNumEvents read from board: " + maxNumEventsIB.get(0) );
    consolFile.println( "maxNumEvents read from board: " + maxNumEventsIB.get(0) );
  }
}


////////////////////////////////////////////////////////////////////////////////
void reset() {
  int err = MyCAENDigitizer.CAEN_DGTZ_Reset(boardHandle);
  if ( noError(err) ) {
    println( "Board has been reset" );
    consolFile.println( "Board has been reset" );
  }
}


////////////////////////////////////////////////////////////////////////////////
void setRecordLength(int recordLength) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetRecordLength(boardHandle, recordLength);
  if ( noError(err) ) {
    println( "Record Length set to " + recordLength);
    consolFile.println( "Record Length set to " + recordLength);
  }
}

int getRecordLength() {
  IntBuffer recordLengthIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetRecordLength(boardHandle, recordLengthIB);
  if ( noError(err) ) {
    println( "Actual Record Length read from board: " + recordLengthIB.get(0) );
    consolFile.println( "Actual Record Length read from board: " + recordLengthIB.get(0) );
    return recordLengthIB.get(0);
  } else return 0;
}

int getRecordLength(IntBuffer recordLengthIB) {
  return MyCAENDigitizer.CAEN_DGTZ_GetRecordLength(boardHandle, recordLengthIB);
}


////////////////////////////////////////////////////////////////////////////////
void setChannelEnableMask(int mask) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetChannelEnableMask(boardHandle, mask);
  if ( noError(err) ) {
    println( "Channel Enable Mask set to " + binary(mask, 16) );
    consolFile.println( "Channel Enable Mask set to " + binary(mask, 16) );
  }
}

void getChannelEnableMask() {
  IntBuffer maskIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetChannelEnableMask(boardHandle, maskIB);
  if ( noError(err) ) {
    println( "Channel Enable Mask read from board: " + maskIB.get(0) );
    consolFile.println( "Channel Enable Mask read from board: " + maskIB.get(0) );
  }
}


////////////////////////////////////////////////////////////////////////////////
void setGroupEnableMask(int mask) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetGroupEnableMask(boardHandle, mask);
  if ( noError(err) ) {
    println( "Group Enable Mask set to " + binary(mask, 4) );
    consolFile.println( "Group Enable Mask set to " + binary(mask, 4) );
  }
}

void getGroupEnableMask() {
  IntBuffer maskIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetGroupEnableMask(boardHandle, maskIB);
  if ( noError(err) ) {
    println( "Group Enable Mask read from board: " + maskIB.get(0) );
    consolFile.println( "Group Enable Mask read from board: " + maskIB.get(0) );
  }
}


////////////////////////////////////////////////////////////////////////////////
void setChannelTriggerThreshold(int ch, int tValue) {
  int tValueAux = tValue;
  if ( modelName.equals("DT5743") ) tValueAux = 0xFFFF - (tValue << 4);  // need parentheses because - has higher precedence than <<
  int err = MyCAENDigitizer.CAEN_DGTZ_SetChannelTriggerThreshold(boardHandle, ch, tValueAux);
  if ( noError(err) ) {
    //println( "Ch" + ch + " trigger threshold set to " + tValue );
    consolFile.println( "Ch" + ch + " trigger threshold set to " + tValue );
  }
}

int getChannelTriggerThreshold(int ch) {
  IntBuffer tValueIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetChannelTriggerThreshold(boardHandle, ch, tValueIB);
  if ( noError(err) ) {
    int tValue = tValueIB.get(0);
    if ( modelName.equals("DT5743") ) tValue = (0xFFFF - tValue) >> 4;
    //println( "Ch" + ch + " trigger threshold read from board: " + tValue );
    consolFile.println( "Ch" + ch + " trigger threshold read from board: " + tValue );
    return tValue;
  } else return -1;
}


////////////////////////////////////////////////////////////////////////////////
void setChannelDCOffset(int ch, int tValue) {
  int dcOffsetScale743 = 0x10000 / adcNChannels;
  int dcOffsetScale = (0x10000*9) / (adcNChannels*10);
  int tValueAux = 0xFFFF - tValue * dcOffsetScale;
  if ( modelName.equals("DT5743") ) tValueAux = tValue * dcOffsetScale743;
  int err = MyCAENDigitizer.CAEN_DGTZ_SetChannelDCOffset( boardHandle, ch, tValueAux);  // scale to 0xFFFF
  if ( noError(err) ) {
    println( "Ch" + ch + " DC offset set to " + tValue );
    println( "Ch" + ch + " DC offset set to " + tValueAux );
    consolFile.println( "Ch" + ch + " DC offset set to " + tValue );
  }
}

int getChannelDCOffset(int ch) {
  IntBuffer tValueIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetChannelDCOffset(boardHandle, ch, tValueIB);
  if ( noError(err) ) {
    int dcOffsetScale743 = 0x10000 / adcNChannels;
    int dcOffsetScale = (0x10000*9) / (adcNChannels*10);
    int tValue = ( 0xFFFF - tValueIB.get(0) ) / dcOffsetScale;  // scale back from 0xFFFF
    if ( modelName.equals("DT5743") ) tValue = tValueIB.get(0) / dcOffsetScale743;
    println( "Ch" + ch + " DC offset read from board: " + tValueIB.get(0) );
    println( "Ch" + ch + " DC offset read from board: " + tValue );
    consolFile.println( "Ch" + ch + " DC offset read from board: " + tValue );
    return tValue;
  } else return -1;
}

//int getChannelDCOffset(int ch, IntBuffer tValueIB) {
//  return MyCAENDigitizer.CAEN_DGTZ_GetChannelDCOffset(boardHandle, ch, tValueIB);
//}


////////////////////////////////////////////////////////////////////////////////
void setChannelSelfTrigger(int mode, int channelmask) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetChannelSelfTrigger(boardHandle, mode, channelmask);
  if ( noError(err) ) {
    println( "Self Trigger mode set to " + mode + " on channels " + binary(channelmask, 16) );
    consolFile.println( "Self Trigger mode set to " + mode + " on channels " + binary(channelmask, 16) );
  }
}

void getChannelSelfTrigger(int ch) {
  IntBuffer modeIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetChannelSelfTrigger(boardHandle, ch, modeIB);
  if ( noError(err) ) {
    println( "Ch" + ch + " Self Trigger mode read from board: " + modeIB.get(0) );
    consolFile.println( "Ch" + ch + " Self Trigger mode read from board: " + modeIB.get(0) );
  }
}


////////////////////////////////////////////////////////////////////////////////
void setSWTriggerMode(int mode) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetSWTriggerMode(boardHandle, mode);
  if ( noError(err) ) {
    println( "Software Trigger mode set to " + mode );
    consolFile.println( "Software Trigger mode set to " + mode );
  }
}

void getSWTriggerMode() {
  IntBuffer modeIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetSWTriggerMode(boardHandle, modeIB);
  if ( noError(err) ) {
    println( "Software Trigger mode read from board: " + modeIB.get(0) );
    consolFile.println( "Software Trigger mode read from board: " + modeIB.get(0) );
  }
}


////////////////////////////////////////////////////////////////////////////////
void mallocReadoutBuffer() {
  IntBuffer sizeIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_MallocReadoutBuffer(boardHandle, refToBufferPointer, sizeIB);
  if ( noError(err) ) {
    println( "Allocated buffer size: " + sizeIB.get(0) + " bytes" );
    consolFile.println( "Allocated buffer size: " + sizeIB.get(0) + " bytes" );
  }
}

void freeReadoutBuffer() {
  int err = MyCAENDigitizer.CAEN_DGTZ_FreeReadoutBuffer(refToBufferPointer);
  if ( noError(err) ) {
    println("Readout Buffer released");
    consolFile.println("Readout Buffer released");
  }
}


////////////////////////////////////////////////////////////////////////////////
void swStartAcquisition() {
  int err = MyCAENDigitizer.CAEN_DGTZ_SWStartAcquisition(boardHandle);
  if ( noError(err) ) {
    println("\nAcquisition started");
    consolFile.println("\nAcquisition started");
  }
}

void swStopAcquisition() {
  int err = MyCAENDigitizer.CAEN_DGTZ_SWStopAcquisition(boardHandle);
  if ( noError(err) ) {
    println("Acquisition stopped\n");
    consolFile.println("Acquisition stopped\n");
  }
}


////////////////////////////////////////////////////////////////////////////////
void sendSWtrigger() {
  int err = MyCAENDigitizer.CAEN_DGTZ_SendSWtrigger(boardHandle);
  if ( noError(err) ) {
    //println("SW Trigger sent");
  }
}


////////////////////////////////////////////////////////////////////////////////
void clearData() {
  int err = MyCAENDigitizer.CAEN_DGTZ_ClearData(boardHandle);
  if ( noError(err) ) {
    println("clear the data stored in the buffers of the digitizer");
    consolFile.println("clear the data stored in the buffers of the digitizer");
    digitizerBufferHasBeenCleared = true;
  }
}


////////////////////////////////////////////////////////////////////////////////
void readDataFromDigitizer() {
  int mode = CAEN_DGTZ_ReadMode_t.CAEN_DGTZ_SLAVE_TERMINATED_READOUT_MBLT;
  Pointer bufferPointer = refToBufferPointer.getValue();
  int err = MyCAENDigitizer.CAEN_DGTZ_ReadData(boardHandle, mode, bufferPointer, bufferSizeIB);
  if ( noError(err) ) {
    //println( "size of the data block read from board: " + bufferSizeIB.get(0) + " bytes" );
  }
}


////////////////////////////////////////////////////////////////////////////////
int getNumEvents() {
  Pointer bufferPointer = refToBufferPointer.getValue();
  IntBuffer numEventsIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetNumEvents(boardHandle, bufferPointer, bufferSizeIB.get(0), numEventsIB);
  if ( noError(err) ) {
    return numEventsIB.get(0);
  } else return -1;
}


/**************************************************************************//**
 * \brief     Retrieves info on and pointer to a specific event
 *
 * \param     [IN] boardHandle        : digitizer handle
 * \param     [IN] bufferPointer      : Address of the acquisition buffer
 * \param     [IN] bufferSizeIB       : acquisition buffer size (in samples)
 * \param     [IN] eventIndex         : index of a specific event stored in the acquisition buffer
 * \param     [OUT] eventInfoStruct   : event info structure containing the information about the specified event
 * \param     [OUT] refToEventPointer : pointer to the requested event in the acquisition buffer
 * \return  0 = Success; negative numbers are error codes
 ******************************************************************************/
////////////////////////////////////////////////////////////////////////////////
EventInfo_t getEventInfo(int eventIndex) {
  Pointer bufferPointer = refToBufferPointer.getValue();
  EventInfo_t eventInfoStruct = new EventInfo_t();
  int err = MyCAENDigitizer.CAEN_DGTZ_GetEventInfo(boardHandle, bufferPointer, bufferSizeIB.get(0), eventIndex, eventInfoStruct, refToEventPointer);
  if ( noError(err) ) {
    //println("Event Size: " + eventInfoStruct.EventSize);
    //String s = bufferPointer.dump(0,8);
    //println( s );
    //int i = bufferPointer.getInt(4);
    //s = hex(i);
    //println( s );
    return eventInfoStruct;
  } else return null;
}


/**************************************************************************//**
 * \brief     Decodes a specified event stored in the acquisition buffer
 *
 * \param     [IN]  boardHandle             : digitizer handle
 * \param     [IN]  eventPointer            : pointer to the requested event in the acquisition buffer
 * \param     [OUT] refToEventStructPointer : event structure with the requested event data
 * \return  0 = Success; negative numbers are error codes
 ******************************************************************************/
////////////////////////////////////////////////////////////////////////////////
UINT16_EVENT_t decodeEvent() {
  Pointer eventPointer = refToEventPointer.getValue();  // returned by getEventInfo()
  int err = MyCAENDigitizer.CAEN_DGTZ_DecodeEvent(boardHandle, eventPointer, refToEventStructPointer);
  if ( noError(err) ) {
    Pointer eventStructPointer = refToEventStructPointer.getValue();
    UINT16_EVENT_t eventStruct = new UINT16_EVENT_t(eventStructPointer);
    //println("The number of samples stored in DataChannel array: " + eventStruct.ChSize[0]);
    ////println("The number of samples stored in DataChannel array: " + eventStructPointer.getInt(0));

    // a kovetkezo ket sorral is mukodik:
    //int[] ChSize = eventStructPointer.getIntArray(0, 64);
    //println("The number of samples stored in DataChannel array: " + ChSize[0]);

    return eventStruct;
  } else return null;
}


////////////////////////////////////////////////////////////////////////////////
CAEN_DGTZ_X743_EVENT_t decodeX743Event() {
  Pointer eventPointer = refToEventPointer.getValue();
  int err = MyCAENDigitizer.CAEN_DGTZ_DecodeEvent(boardHandle, eventPointer, refToEventStructPointer);
  if ( noError(err) ) {
    Pointer eventStructPointer = refToEventStructPointer.getValue();
    CAEN_DGTZ_X743_EVENT_t eventStruct = new CAEN_DGTZ_X743_EVENT_t(eventStructPointer);
    //println("The number of samples stored in DataChannel array: " + eventStruct.ChSize[0]);
    ////println("The number of samples stored in DataChannel array: " + eventStructPointer.getInt(0));

    // a kovetkezo ket sorral is mukodik:
    //int[] ChSize = eventStructPointer.getIntArray(0, 64);
    //println("The number of samples stored in DataChannel array: " + ChSize[0]);


    return eventStruct;
  } else return null;
}


////////////////////////////////////////////////////////////////////////////////
CAEN_DGTZ_X743_EVENT1_t decodeX743Event1() {
  Pointer eventPointer = refToEventPointer.getValue();
  int err = MyCAENDigitizer.CAEN_DGTZ_DecodeEvent(boardHandle, eventPointer, refToEventStructPointer);
  if ( noError(err) ) {
    Pointer eventStructPointer = refToEventStructPointer.getValue();
    CAEN_DGTZ_X743_EVENT1_t eventStruct = new CAEN_DGTZ_X743_EVENT1_t(eventStructPointer);

    return eventStruct;
  } else return null;
}


////////////////////////////////////////////////////////////////////////////////
void allocateEvent() {
  int err = MyCAENDigitizer.CAEN_DGTZ_AllocateEvent(boardHandle, refToEventStructPointer);
  if ( noError(err) ) {
    println("allocate memory buffer for the decoded event data");
    consolFile.println("allocate memory buffer for the decoded event data");
  }
}

void freeEvent() {  // This function releases the event memory buffer allocated by either the DecodeEvent or AllocateEvent function.
  int err = MyCAENDigitizer.CAEN_DGTZ_FreeEvent(boardHandle, refToEventStructPointer);
  if ( noError(err) ) {
    println("release memory buffer of the decoded event data");
    consolFile.println("release memory buffer of the decoded event data");
  }
}


////////////////////////////////////////////////////////////////////////////////
void disconnect() {
  int err = MyCAENDigitizer.CAEN_DGTZ_CloseDigitizer(boardHandle);
  if ( noError(err) ) {
    println("Disconnected");
    consolFile.println("Disconnected");
  }
}


////////////////////////////////////////////////////////////////////////////////
void writeRegister(int address, int data) {
  int err = MyCAENDigitizer.CAEN_DGTZ_WriteRegister(boardHandle, address, data);
  if ( noError(err) ) {
    println( hex(data) + " written to address " + hex(address) );
    consolFile.println( hex(data) + " written to address " + hex(address) );
  }
}

void readRegister(int address) {
  IntBuffer dataIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_ReadRegister(boardHandle, address, dataIB);
  if ( noError(err) ) {
    println( hex(dataIB.get(0)) + " read from address " + hex(address) );
    consolFile.println( hex(dataIB.get(0)) + " read from address " + hex(address) );
  }
}


////////////////////////////////////////////////////////////////////////////////
void setPostTriggerSize(int percent) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetPostTriggerSize(boardHandle, percent);
  if ( noError(err) ) {
    println( "Post-trigger size set to " + percent + " %" );
    consolFile.println( "Post-trigger size set to " + percent + " %" );
  }
}

int getPostTriggerSize() {
  IntBuffer percentIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetPostTriggerSize(boardHandle, percentIB);
  if ( noError(err) ) {
    println( "Actual Post-trigger size read from board: " + percentIB.get(0) + " %" );
    consolFile.println( "Actual Post-trigger size read from board: " + percentIB.get(0) + " %" );
    return percentIB.get(0);
  } else return -1;
}


////////////////////////////////////////////////////////////////////////////////
void setSAMPostTriggerSize(int SamIndex, int value) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetSAMPostTriggerSize(boardHandle, SamIndex, value);
  if ( noError(err) ) {
    println( "SAM Post-trigger size at SamIndex " + SamIndex + " set to " + value);
    consolFile.println( "SAM Post-trigger size at SamIndex " + SamIndex + " set to " + value);
  }
}

int getSAMPostTriggerSize(int SamIndex) {
  IntBuffer percentIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetSAMPostTriggerSize(boardHandle, SamIndex, percentIB);
  if ( noError(err) ) {
    println( "Actual SAM Post-trigger size at SamIndex " + SamIndex + " read from board: " + percentIB.get(0));
    consolFile.println( "Actual SAM Post-trigger size at SamIndex " + SamIndex + " read from board: " + percentIB.get(0));
    return percentIB.get(0);
  } else return -1;
}


////////////////////////////////////////////////////////////////////////////////
void setSAMSamplingFrequency(int frequency) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetSAMSamplingFrequency(boardHandle, frequency);
  if ( noError(err) ) {
    println( "SAM frequency set to " + frequency);
    consolFile.println( "SAM frequency set to " + frequency );
  }
}

int getSAMSamplingFrequency() {
  IntBuffer frequencyIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetSAMSamplingFrequency(boardHandle, frequencyIB);
  if ( noError(err) ) {
    println( "SAM frequency read from board: " + frequencyIB.get(0));
    consolFile.println( "SAM frequency read from board: " + frequencyIB.get(0));
    return frequencyIB.get(0);
  } else return -1;
}


////////////////////////////////////////////////////////////////////////////////
void setSAMAcquisitionMode(int mode) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetSAMAcquisitionMode(boardHandle, mode);
  if ( noError(err) ) {
    println( "SAM aquisition mode set to " + mode);
    consolFile.println( "SAM aquisition mode set to " + mode );
  }
}

int getSAMAcquisitionMode() {
  IntBuffer modeIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetSAMAcquisitionMode(boardHandle, modeIB);
  if ( noError(err) ) {
    println( "SAM aquisition mode read from board: " + modeIB.get(0));
    consolFile.println( "SAM aquisition mode read from board: " + modeIB.get(0));
    return modeIB.get(0);
  } else return -1;
}


////////////////////////////////////////////////////////////////////////////////
void setChannelPairTriggerLogic(int channelA, int channelB, int logic, short coincidenceWindow) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetChannelPairTriggerLogic(boardHandle, channelA, channelB, logic, coincidenceWindow);
  if ( noError(err) ) {
    println( "x743 (" + channelA + ", " + channelB + ") channel pair trigger logic set to " + logic);
    consolFile.println( "x743 (" + channelA + ", " + channelB + ") channel pair trigger logic set to " + logic);
    println( "x743 (" + channelA + ", " + channelB + ") channel pair coinc. window set to " + coincidenceWindow + "ns");
    consolFile.println( "x743 (" + channelA + ", " + channelB + ") channel pair coinc. window set to " + coincidenceWindow + "ns");
  }
}

void getChannelPairTriggerLogic(int channelA, int channelB) {
  IntBuffer logicIB = IntBuffer.allocate(1);
  ShortBuffer coincidenceWindowSB = ShortBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetChannelPairTriggerLogic(boardHandle, channelA, channelB, logicIB, coincidenceWindowSB);
  if ( noError(err) ) {
    println( "x743 (" + channelA + ", " + channelB + ") channel pair trigger logic read from board: " + logicIB.get(0));
    consolFile.println( "x743 (" + channelA + ", " + channelB + ") channel pair trigger logic read from board: " + logicIB.get(0));
    println( "x743 (" + channelA + ", " + channelB + ") channel pair coinc. window read from board: " + coincidenceWindowSB.get(0) + "ns");
    consolFile.println( "x743 (" + channelA + ", " + channelB + ") channel pair coinc. window read from board: " + coincidenceWindowSB.get(0) + "ns");
  }
}


////////////////////////////////////////////////////////////////////////////////
void setTriggerLogic(int logic, int majorityLevel) {
  int err = MyCAENDigitizer.CAEN_DGTZ_SetTriggerLogic(boardHandle, logic, majorityLevel);
  if ( noError(err) ) {
    println( "x743 trigger logic set to " + logic);
    consolFile.println( "x743 trigger logic set to " + logic);
    println( "x743 trigger majorityLevel set to " + majorityLevel);
    consolFile.println( "x743 trigger majorityLevel set to " + majorityLevel);
  }
}

void getTriggerLogic() {
  IntBuffer logicIB = IntBuffer.allocate(1);
  IntBuffer majorityLevelIB = IntBuffer.allocate(1);
  int err = MyCAENDigitizer.CAEN_DGTZ_GetTriggerLogic(boardHandle, logicIB, majorityLevelIB);
  if ( noError(err) ) {
    println( "x743 trigger logic read from board: " + logicIB.get(0));
    consolFile.println( "x743 trigger logic read from board: " + logicIB.get(0));
    println( "x743 trigger majorityLevel read from board: " + majorityLevelIB.get(0));
    consolFile.println( "x743 trigger majorityLevel read from board: " + majorityLevelIB.get(0));
  }
}





boolean  noError(int err) {
  if (err != 0) {
    String methodName = new Throwable()
      .getStackTrace()[1]
      .getMethodName();
    println(methodName + " error: " + err);
    consolFile.println(methodName + " error: " + err);
  }
  return (err == 0);
}
