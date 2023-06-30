// 2022.11.02. több csatornás nem fapados változat JTable táblázattal
// (a sketch_118d_MyCAENDig_Hunyadi és a sketch_133c_jtable_Hunyadi_test öszeolvasztása)
// 2022.11.18. multiplicity, event counter on plot added
// 2022.12.01. event rate display modified
// 2022.12.12. detectWindowResizeThread removed, placed in draw()
// 2022.12.14. process pulses of any polarity based on trig. pol.
// 2023.02.13. start/stop button
// 2023.02.13. clear histograms button
// 2023.02.16. pre.tr and post.tr vertical lines for selected channel
// 2023.02.17. fix trigger jitter in plot with chTrigPosMax
// 2023.02.17. simplify trigLineThread
// 2023.02.20. mainPulse... variables renamed to ch...
// 2023.02.20. processSERPulses() in new ser tab
// 2023.02.21. JOptionPane if no device is found
// 2023.02.21. lineThread instead of trigLineThread
// 2023.02.23. fix chTrigPosMax bug with "if ( trigLineWidth == 2 ) continue;"
// 2023.02.24. lineThread now gets idle when mousePressed to prevent plot panning at limits
// 2023.02.27. fix another chTrigPosMax bug with "if ( chTrigPosMax - chTrigPosValid  < 30 )..."
// 2023.02.28. integralHisto will contain overrange pulses if roiMax == integralHistoNBins - 1...
//             ...this helps finding the spectrum when hist.scale is too low
// 2023.03.02. use nfc() to place commas to mark units of 1000
// 2023.03.02. new ch0TrigIsCommon in global config
// 2023.03.17. new openDevice2() for CAEN_DGTZ_OpenDigitizer2()
// 2023.03.17. new setSAMPostTriggerSize()
// 2023.03.28. safe mechanism for lastUsedAdcNChannels
// 2023.03.29. new setGroupEnableMask()
// 2023.03.30. renamed eventNumberInBuffer to eventIndex in getEventInfo() and ...
//             ... numEvent also to eventIndex in CAEN_DGTZ_GetEventInfo()
// 2022.03.30.new setSAMSamplingFrequency() and SAMFrequency_t
// 2022.03.30.new setSAMAcquisitionMode() and SAMAcquisitionMode_t

String version = "2023.06.12";

//for limiting window resize:
import processing.awt.PSurfaceAWT.SmoothCanvas;
import javax.swing.JFrame;
import java.awt.Dimension;

// geomerative library: http://www.ricardmarxer.com/geomerative/documentation/index.html
import geomerative.*;

// message box
import javax.swing.JOptionPane;

//Do not import grafica, use it locally in Processing syntax
GPlotE plot;

int boardHandle;
//PointerByReference refToBufferPointer = new PointerByReference(Pointer.NULL);
PointerByReference refToBufferPointer = new PointerByReference(null);
IntBuffer bufferSizeIB = IntBuffer.allocate(1);  // acquisition buffer size (in samples)
PointerByReference refToEventPointer = new PointerByReference(null);
PointerByReference refToEventStructPointer = new PointerByReference(null);
CAEN_DGTZ_BoardInfo_t boardInfoStruct;

boolean serIsEnabled = false;
boolean saveToFileIsEnabled = false;
boolean autoTrigIsEnabled = true;
//int recordLength = 28_000_000;
int recordLength = 1_000;
int postTrigPercent = 99;
int samPostTrigSize = 20;
String modelName = "";

int trigLevelSER = 4;
int nPointsPreSER = 10;
int nPointsPostSER = 200;
int channelEnableMask = unbinary("0001");  // which channels are enabled
int channelTriggerMask = unbinary("1111");  // which channels can trigger an event
String timeUnit = "(1 ns)";

int numEvents;
int eventCounter = -1;
int eventSavedCounter = 0;
float eventRate = 0;
float eventSavedRate = 0;

//int chMask = 0;
int adcNChannels;
int nChannels;
int chSelected = 0;
GPointsArray points = new GPointsArray();
boolean digitizerBufferHasBeenCleared = false;
boolean readWformThreadIsEnabled = true;
boolean readWformThreadIsBusy = false;
//int waveformPlotMaxXLength = 400_000;


boolean readWformThreadModPlotReq = false;
boolean readWformThreadModPlotAcq = false;
boolean lineThreadModPlotReq = false;
boolean lineThreadModPlotAcq = false;
boolean drawModPlotReq = false;
boolean drawModPlotAcq = false;

boolean plotIsPaused = false;  // toggled with SPACE key
String debug = "";
//int dec = recordLength / 40000;

PrintWriter serOutFile;
PrintWriter[] chOutFiles = new PrintWriter[16];
PrintWriter consolFile;


void setup() {
  size(1000, 600);

  //surface.setResizable(true);
  windowResizable(true);  // ugyanaz, mint az elozo sor
  //surface.setTitle("Atomki CAEN Digitalizer - ver." + version);

  // log file in the sketch data folder
  consolFile = createWriter("data/consol.txt");

  // Start detectWindowResizeThread (thread also keeps redrawing everything at 5 Hz)
  //thread("detectWindowResizeThread");

  // Limit sketch window minimum size
  SmoothCanvas sc = (SmoothCanvas) getSurface().getNative();
  JFrame jf = (JFrame) sc.getFrame();
  Dimension d = new Dimension(720, 360);
  jf.setMinimumSize(d);

  // load config.txt  if it exists
  if ( !config() ) {
    JOptionPane.showMessageDialog(null, "No config.txt file found in the sketch folder");
    super.exit();
    return;
  }

  // try to open device
  if ( !openDevice2( globalConfigTable.getInt("USBLinkNum", 0), globalConfigTable.getInt("VMEBaseAddress", 0) ) ) {

    String title = "No Device Found";
    int n = JOptionPane.showConfirmDialog(null, "Would you like to modify Global Config?", title, JOptionPane.YES_NO_OPTION);
    if (n == JOptionPane.YES_OPTION) {
      frameGlConfig.setVisible(true);
      while ( frameGlConfig.isVisible() ) delay(200);
      updateConfigFile();
      title = "Global Config Updated";
    }
    n = JOptionPane.showConfirmDialog(null, "Would you like to modify Channel Config?", title, JOptionPane.YES_NO_OPTION);
    if (n == JOptionPane.YES_OPTION) {
      frameChConfig.setVisible(true);
      while ( frameChConfig.isVisible() ) delay(200);
      updateConfigFile();
    }
    super.exit();
    return;
  }


  startDigitizer();

  // geomerative library
  RG.init(this);
  RG.setPolygonizer(RG.ADAPTATIVE);

  // Create a new plot
  plot = new GPlotE(this);

  // Set the plot title and the axis labels
  plot.setTitleText("Caen " + modelName + " waveforms");
  plot.getXAxis().setAxisLabelText(timeUnit);
  plot.getYAxis().setAxisLabelText("(ADC channel)");

  plot.isOnTop = true;  // we only have a single plot

  // set preSER and postSER values if serIsEnabled
  if (serIsEnabled) {
    nPointsPreSER = channelConfigTable.getInt(16, "pre.tr");
    nPointsPostSER = channelConfigTable.getInt(16, "post.tr");
    trigLevelSER = channelConfigTable.getInt(16, "thres");
  }

  // corner points of digitizer's limiting ranges (rectangle)
  points.add(0, 0);
  points.add(0, adcNChannels-1);
  points.add(recordLength-1, adcNChannels-1);
  points.add(recordLength-1, 0);

  // add corner points to main layer to get proper autoscale
  plot.getMainLayer().addPoints(points);
  plot.updateLimits();

  // create output files if save to file is enabled
  if (saveToFileIsEnabled) {
    if (serIsEnabled)
      serOutFile = createWriter("SER_" + getTimeStampForFilename() + ".txt");  // object to print to a text-output stream
    else
      for (int ch=0; ch < nChannels; ch++) {
        int aux = channelEnableMask & (1 << ch);
        if ( aux != 0) {
          //chOutFiles[ch] = createWriter("ch" + ch + "_" + getTimeStampForFilename() + ".txt");  // object to print to a text-output stream
          chOutFiles[ch] = createWriter("wave" + ch + ".c3.txt");  // object to print to a text-output stream
        }
      }
  }

  thread("readWformThread");

  thread("plotArbiterThread");  // triggers each 10 ms

  thread("lineThread");  // triggers each 100 ms

  textSize(18);
  fill(200, 100, 0);  // fill(red, green, blue)
  createGUI();
}

void draw() {
  float[] value = plot.getValueAt(mouseX, mouseY);
  String coord = "";
  if ( plot.isOverBox(mouseX, mouseY) )
    coord = "    (" + nfc(value[0], 1) + "  " + nfc(value[1], 1) + ")";

  surface.setTitle("Atomki CAEN Digitalizer - ver." + version + coord);
  background(222);

  drawModPlotReq = true;
  while (!drawModPlotAcq) delay(10);

  opWaveform.moveTo( opWaveform.getX(), height - 25 );
  opIntegralHisto.moveTo( opIntegralHisto.getX(), height - 25 );
  if (serIsEnabled) {
    opTimeHisto.moveTo( opTimeHisto.getX(), height - 25 );
    op2d.moveTo( op2d.getX(), height - 25 );
  }

  plot.setOuterDim( plot.defaultOuterDim );  // windowResized() miatt
  plot.draw();
  //plot.getLayer("0").drawHorizontalLine(620);

  if (waveformPlotIsEnabled) {
    plot.beginDraw();
    drawRectangle( points, color(230, 50) );  // geomerative library
    plot.setFontSize(20);
    plot.setFontColor(color(200, 100, 0));  // color(red, green, blue)
    plot.drawAnnotation("Digitizer", 0, adcNChannels, LEFT, BOTTOM);

    int lineColor = plot.boyntonOptimized[ chSelected % plot.boyntonOptimized.length ];

    plot.drawHorizontalLine( channelConfigTable.getInt(chSelected, "thres"), lineColor, trigLineWidth );

    if (chSelTrigPos != -1) {
      int preTrig= channelConfigTable.getInt(chSelected, "pre.tr");
      if (chSelTrigPosMovAve > 20)
        preTrig = constrain( preTrig, 1, chSelTrigPosMovAve - 20 );
      else
        preTrig = 0;
      channelConfigTable.setInt(preTrig, chSelected, "pre.tr");
      plot.drawVerticalLine( chSelTrigPosMovAve - preTrig, lineColor, preTrigLineWidth );

      plot.drawVerticalLine( chSelTrigPosMovAve + channelConfigTable.getInt(chSelected, "post.tr"), lineColor, postTrigLineWidth );
    }

    // add dummy points to the main layer to prevent plot autoscale jitter
    plot.addPoint(-40, 0);
    plot.addPoint(recordLength+40, 0);
    plot.endDraw();
  }

  if (integralHistoPlotIsEnabled) {
    plot.beginDraw();
    int lineColor = plot.boyntonOptimized[ chSelected % plot.boyntonOptimized.length ];
    plot.drawVerticalLine( channelConfigTable.getInt(chSelected, "roi.min"), lineColor, roiMinLineWidth );
    plot.drawVerticalLine( channelConfigTable.getInt(chSelected, "roi.max"), lineColor, roiMaxLineWidth );
    plot.endDraw();
  }

  drawModPlotReq = false;

  String er = nfc(eventRate, 1);
  String esr = nfc(eventSavedRate, 1);
  //text( er + " -> " + esr + " events/s", width - (er.length() + esr.length() + 12) * 10, 30 );
  text( "cps in/out:  " + er + " / " + esr, width - (er.length() + esr.length() + 11) * 10, 30 );
  String ec = "Event Counter:  " + nfc(eventCounter+1);
  text( ec, width-ec.length()*10+20, height-15 );
  text(debug, 150, 30);
  //delay(3000);

  check_focus();
  if (frameCount > 1) noLoop();

  //println("chSelTrigPos = " + chSelTrigPos);  // debug
}


void startDigitizer() {

  // reset the Digitizer; all internal registers and states are restored to default values
  reset();

  // read serial number, model, number of channels, firmware release, and other parameters from the board
  boardInfoStruct = getInfo();

  modelName = trim( new String(boardInfoStruct.ModelName) );
  switch (modelName) {
  case "DT5751":
    timeUnit = "(1 ns)";
    break;
  case "DT5725":
    timeUnit = "(4 ns)";
    break;
  case "V1761C":
    timeUnit = "(0.25 ns)";
    break;
  case "V1730D":
    timeUnit = "(2 ns)";
    break;
  case "DT5743":
    timeUnit = "(" + (String) globalConfigTable.getValueAt("DT5743Period_(ns)_", 0) + " ns)";
    break;
  default:
    timeUnit = "(? ns)";
  }
  println("ADC timeUnit: " + timeUnit);
  consolFile.println("ADC timeUnit: " + timeUnit);


  // get number of ADC bits from boardInfoStruct
  int adcNBits = boardInfoStruct.ADC_NBits;
  println("ADC resolution: " + adcNBits + " bits");
  consolFile.println("ADC resolution: " + adcNBits + " bits");


  // calculate number of ADC channels
  adcNChannels = (int) pow(2, adcNBits);


  // get number of channels from boardInfoStruct
  nChannels = boardInfoStruct.Channels;
  if ( modelName.equals("DT5743") ) nChannels *=2;  // Hibasan, csak a felet adja a boardInfoStruct!
  println("Number of Analog Input Channels: " + nChannels);
  consolFile.println("Number of Analog Input Channels: " + nChannels);

  println("\nInitalizing board with config file parameters:");
  consolFile.println("\nInitalizing board with config file parameters:");

  // set desired number of waveform samples = time scale
  setRecordLength(recordLength);
  recordLength = getRecordLength();  // get actual value
  globalConfigTable.setInt(recordLength, "recordLength", 0);

  if ( !modelName.equals("DT5743") ) {
    // set trigger point to (100% - postTrigPercent) of recordLength
    setPostTriggerSize(postTrigPercent);
    getPostTriggerSize();
  } else {
    //println(modelName);
    int nSamBlocks = 4;
    for (int samIndex = 0; samIndex < nSamBlocks; samIndex++) {
      switch(samIndex) {
      case 0:
        samPostTrigSize = globalConfigTable.getInt("DT5743PostTrigSize_ch0-ch1_", 0);
        break;
      case 1:
        samPostTrigSize = globalConfigTable.getInt("DT5743PostTrigSize_ch2-ch3_", 0);
        break;
      case 2:
        samPostTrigSize = globalConfigTable.getInt("DT5743PostTrigSize_ch4-ch5_", 0);
        break;
      case 3:
        samPostTrigSize = globalConfigTable.getInt("DT5743PostTrigSize_ch6-ch7_", 0);
        break;
      default:
      }
      setSAMPostTriggerSize(samIndex, samPostTrigSize);
      getSAMPostTriggerSize(samIndex);
    }
  }

  // set maximum number of events for each block transfer
  setMaxNumEventsBLT( globalConfigTable.getInt("maxNumEventsBLT", 0) );

  // set if software trigger participates in the global trigger generation and/or is propagated on TRG-OUT
  setSWTriggerMode(TriggerMode_t.CAEN_DGTZ_TRGMODE_ACQ_AND_EXTOUT);

  // set acquisition mode: sw start/stop, GPI level start/stop, TRG IN rising edge start/ sw stop
  setAcquisitionMode(AcqMode_t.SW_CONTROLLED);

  // Sets the number of buffers in which the channel memory can be divided.
  //writeRegister(0x800c,0x09);
  //readRegister(0x800c);

  // set which channels are enabled
  String chEnMaskString = "";
  for (int ch=0; ch < nChannels; ch++) {
    chEnMaskString = (String)channelConfigTable.getValueAt(ch, "on") + chEnMaskString;
  }
  // enable ch0 alone if serIsEnabled
  if (serIsEnabled) chEnMaskString = binary(1, nChannels);
  println("chEnMaskString: " + chEnMaskString);
  consolFile.println("chEnMaskString: " + chEnMaskString);
  channelEnableMask = unbinary(chEnMaskString);
  if ( !modelName.equals("DT5743") ) {
    setChannelEnableMask(channelEnableMask);
  } else {
    // set which groups are enabled
    String grEnMaskString = "";
    for (int gr=0; gr < 4; gr++) {
      String s = "";
      if ( channelConfigTable.getInt(gr*2, "on") == 1 || channelConfigTable.getInt(gr*2+1, "on") == 1 ) s = "1";
      else s = "0";
      grEnMaskString = s + grEnMaskString;
    }
    println("grEnMaskString: " + grEnMaskString);
    consolFile.println("grEnMaskString: " + grEnMaskString);
    int groupEnableMask = unbinary(grEnMaskString);
    setGroupEnableMask(groupEnableMask);
  }

  if ( modelName.equals("DT5743") ) {
    getSAMAcquisitionMode();
    timeUnit = (String) globalConfigTable.getValueAt("DT5743Period_(ns)_", 0);
    int samplingFreq = 0;
    switch ( timeUnit ) {
    case "0.3125":
      samplingFreq = 0;  // 3.2 GS/s
      break;
    case "0.625":
      samplingFreq = 1;  // 1.6 GS/s
      break;
    case "1.25":
      samplingFreq = 2;  // 800 MS/s
      break;
    case "2.5":
      samplingFreq = 3;  // 400 MS/s
      break;
    default:
      samplingFreq = 0;
    }
    setSAMSamplingFrequency(samplingFreq);
    switch ( getSAMSamplingFrequency() ) {
    case 0:
      timeUnit = "(0.3125 ns)";  // 3.2 GS/s
      break;
    case 1:
      timeUnit = "(0.625 ns)";  // 1.6 GS/s
      break;
    case 2:
      timeUnit = "(1.25 ns)";  // 800 MS/s
      break;
    case 3:
      timeUnit = "(2.5 ns)";  // 400 MS/s
      break;
    default:
      timeUnit = "(? ns)";
    }
    println("timeUnit: " + timeUnit);

    setX743ChannelPairTriggerLogic(0, 1, 0, (short)100);
    getX743ChannelPairTriggerLogic(0, 1);
    setX743TriggerLogic(0, 1);
    //getTriggerLogic();  // returns error -17 which means "This function is not allowed for this module"
    
    loadSAMCorrectionData();
    
    getSAMCorrectionLevel();
    
    enableSAMPulseGen(0, (short)0xAAAA, 1);
  }  // if ( modelName.equals("DT5743") ) 


  // set which channels participate in the global trigger generation and/or are propagated on TRG-OUT; applies only to channels that have the relevant bit in the mask equal to 1.
  String chTrigMaskString = "";
  for (int ch=0; ch < nChannels; ch++) {
    chTrigMaskString = (String)channelConfigTable.getValueAt(ch, "trig") + chTrigMaskString;
  }
  println("chTrigMaskString: " + chTrigMaskString);
  consolFile.println("chTrigMaskString: " + chTrigMaskString);
  channelTriggerMask = unbinary(chTrigMaskString);
  setChannelSelfTrigger(TriggerMode_t.CAEN_DGTZ_TRGMODE_ACQ_AND_EXTOUT, channelTriggerMask);
  if ( !modelName.equals("DT5743") ) getChannelSelfTrigger(0); // DT5743 returns error -99 which means "The function is not yet implemented"

  // set trigger level for each channel
  for (int ch=0; ch < nChannels; ch++) {
    int thres = channelConfigTable.getInt(ch, "thres") * adcNChannels / lastUsedAdcNChannels;
    thres = constrain(thres, 0, adcNChannels-1);
    channelConfigTable.setInt(thres, ch, "thres");
    setChannelTriggerThreshold( ch, thres );  // set trigger threshold for a specific channel in ADC channels
    getChannelTriggerThreshold( ch);  // get trigger threshold for a specific channel in ADC channels
  }

  // set trigger polarity for each channel
  for (int ch=0; ch < nChannels; ch++) {
    int trigPol = TriggerPolarity_t.TriggerOnFallingEdge;
    if ( channelConfigTable.getValueAt(ch, "tr.pol").equals("pos") ) trigPol = TriggerPolarity_t.TriggerOnRisingEdge;
    setChannelTriggerPolarity( ch, trigPol);  // set trigger polarity for a specific channel
    if ( !modelName.equals("DT5743") ) getChannelTriggerPolarity(ch);  // DT5743 returns error -17 which means "This function is not allowed for this module"
  }

  // set DC offset for each channel in ADC channel units
  for (int ch=0; ch < nChannels; ch++) {
    int offset = channelConfigTable.getInt(ch, "offset") * adcNChannels / lastUsedAdcNChannels;
    offset = constrain(offset, 0, adcNChannels-1);
    channelConfigTable.setInt(offset, ch, "offset");
    setChannelDCOffset( ch, offset );  // set DC offset for a specific channel in ADC channels
  }

  // prepare for further startDigitizer() calls
  lastUsedAdcNChannels = adcNChannels;

  delay(100);  // wait for DC levels to stabilize

  mallocReadoutBuffer();  // allocate memory buffer for data block transfer from digitizer to PC.
  allocateEvent();  // allocate memory buffer for the decoded event data
  swStartAcquisition();  // starts the acquisition in a board using a software command
  readWformThreadIsEnabled = true;
}  // void startDigitizer()




void plotArbiterThread() {
  while (true) {
    boolean plotBusy = drawModPlotAcq || readWformThreadModPlotAcq || lineThreadModPlotAcq;

    if (drawModPlotReq) {
      if (!plotBusy) drawModPlotAcq = true;
    } else drawModPlotAcq = false;
    plotBusy = drawModPlotAcq || readWformThreadModPlotAcq || lineThreadModPlotAcq;

    if (readWformThreadModPlotReq) {
      if (!plotBusy) readWformThreadModPlotAcq = true;
    } else readWformThreadModPlotAcq = false;
    plotBusy = drawModPlotAcq || readWformThreadModPlotAcq || lineThreadModPlotAcq;

    if (lineThreadModPlotReq) {
      if (!plotBusy) lineThreadModPlotAcq = true;
    } else lineThreadModPlotAcq = false;

    delay(10);
  }
}


float trigLineWidth = 1;
float preTrigLineWidth = 1;
float postTrigLineWidth = 1;
float roiMinLineWidth = 1;
float roiMaxLineWidth = 1;
float chSelectedLineWidth = 2;

void lineThread() {
  boolean mouseCloseToTrigLine = false;
  boolean mouseCloseToTrigLinePrev = false;
  boolean mouseCloseToPreTrigLine = false;
  boolean mouseCloseToPreTrigLinePrev = false;
  boolean mouseCloseToPostTrigLine = false;
  boolean mouseCloseToPostTrigLinePrev = false;
  boolean mouseCloseToRoiMinLine = false;
  boolean mouseCloseToRoiMinLinePrev = false;
  boolean mouseCloseToRoiMaxLine = false;
  boolean mouseCloseToRoiMaxLinePrev = false;

  while (true) {
    delay(100);
    if (mousePressed) continue;
    if ( !plot.isOverBox(mouseX, mouseY) ) continue;

    if (waveformPlotIsEnabled) {

      mouseCloseToTrigLinePrev = mouseCloseToTrigLine;  // keep previous value
      int thres = channelConfigTable.getInt(chSelected, "thres");
      float thresScreen = plot.getScreenPosAtValue(0, thres) [1];
      mouseCloseToTrigLine = abs( thresScreen - mouseY ) < 5;// get current value

      if ( chSelTrigPos != -1 ) {
        mouseCloseToPreTrigLinePrev = mouseCloseToPreTrigLine;  // keep previous value
        int pre = chSelTrigPosMovAve - channelConfigTable.getInt(chSelected, "pre.tr");
        float preScreen = plot.getScreenPosAtValue(pre, 0) [0];
        mouseCloseToPreTrigLine = abs( preScreen - mouseX ) < 5;// get current value

        mouseCloseToPostTrigLinePrev = mouseCloseToPostTrigLine;  // keep previous value
        int post = chSelTrigPosMovAve + channelConfigTable.getInt(chSelected, "post.tr");
        float postScreen = plot.getScreenPosAtValue(post, 0) [0];
        mouseCloseToPostTrigLine = abs( postScreen - mouseX ) < 5;// get current value
      }

      if ( preTrigLineWidth != 2 && postTrigLineWidth != 2 ) {
        if ( !mouseCloseToTrigLinePrev && mouseCloseToTrigLine ) {
          plot.deactivatePanning();
          trigLineWidth = 2;
          chSelectedLineWidth = 4;
          loop();
        } else if ( mouseCloseToTrigLinePrev && !mouseCloseToTrigLine ) {
          plot.activatePanning();
          trigLineWidth = 1;
          chSelectedLineWidth = 2;
          loop();
        }
      }

      if ( trigLineWidth != 2 && postTrigLineWidth != 2 ) {
        if ( !mouseCloseToPreTrigLinePrev && mouseCloseToPreTrigLine ) {
          plot.deactivatePanning();
          preTrigLineWidth = 2;
          chSelectedLineWidth = 4;
          loop();
        } else if ( mouseCloseToPreTrigLinePrev && !mouseCloseToPreTrigLine ) {
          plot.activatePanning();
          preTrigLineWidth = 1;
          chSelectedLineWidth = 2;
          loop();
        }
      }

      if ( preTrigLineWidth != 2 && trigLineWidth != 2 ) {
        if ( !mouseCloseToPostTrigLinePrev && mouseCloseToPostTrigLine ) {
          plot.deactivatePanning();
          postTrigLineWidth = 2;
          chSelectedLineWidth = 4;
          loop();
        } else if ( mouseCloseToPostTrigLinePrev && !mouseCloseToPostTrigLine ) {
          plot.activatePanning();
          postTrigLineWidth = 1;
          chSelectedLineWidth = 2;
          loop();
        }
      }
    }

    if (integralHistoPlotIsEnabled) {
      mouseCloseToRoiMinLinePrev = mouseCloseToRoiMinLine;  // keep previous value
      int min = channelConfigTable.getInt(chSelected, "roi.min");
      float minScreen = plot.getScreenPosAtValue(min, 0) [0];
      mouseCloseToRoiMinLine = abs( minScreen - mouseX ) < 5;// get current value

      mouseCloseToRoiMaxLinePrev = mouseCloseToRoiMaxLine;  // keep previous value
      int max = channelConfigTable.getInt(chSelected, "roi.max");
      float maxScreen = plot.getScreenPosAtValue(max, 0) [0];
      mouseCloseToRoiMaxLine = abs( maxScreen - mouseX ) < 5;// get current value

      if ( roiMaxLineWidth != 2 ) {
        if ( !mouseCloseToRoiMinLinePrev && mouseCloseToRoiMinLine ) {
          plot.deactivatePanning();
          roiMinLineWidth = 2;
        } else if ( mouseCloseToRoiMinLinePrev && !mouseCloseToRoiMinLine ) {
          plot.activatePanning();
          roiMinLineWidth = 1;
        }
      }

      if ( roiMinLineWidth != 2 ) {
        if ( !mouseCloseToRoiMaxLinePrev && mouseCloseToRoiMaxLine ) {
          plot.deactivatePanning();
          roiMaxLineWidth = 2;
        } else if ( mouseCloseToRoiMaxLinePrev && !mouseCloseToRoiMaxLine ) {
          plot.activatePanning();
          roiMaxLineWidth = 1;
        }
      }

      loop();
    }
  }  // while (true)
}

void mouseDragged() {
  if ( !(waveformPlotIsEnabled || integralHistoPlotIsEnabled) ) return;

  if (saveToFileIsEnabled) {
    if ( trigLineWidth == 2 || preTrigLineWidth == 2 || postTrigLineWidth == 2 || roiMinLineWidth == 2 || roiMaxLineWidth == 2 ) {
      JOptionPane.showMessageDialog(null, "Can't change value when save to file is enabled");
      return;
    }
  }

  if ( trigLineWidth == 2 ) {
    float[] value = plot.getValueAt(mouseX, mouseY);
    int trigLevelNew = constrain( (int)value[1], 0, adcNChannels - 1 );
    channelConfigTable.setInt(trigLevelNew, chSelected, "thres");
    setChannelTriggerThreshold(chSelected, trigLevelNew);  // set trigger threshold for a specific channel in ADC channels
  } else if ( preTrigLineWidth == 2 ) {
    float[] value = plot.getValueAt(mouseX, mouseY);
    //int preTrigNew = constrain( chTrigPosMax - (int)value[0], 0, chTrigPosMax - 1  );
    int preTrigNew = chSelTrigPosMovAve - (int)value[0];
    channelConfigTable.setInt(preTrigNew, chSelected, "pre.tr");
  } else if ( postTrigLineWidth == 2 ) {
    float[] value = plot.getValueAt(mouseX, mouseY);
    int posTrigNew = constrain( (int)value[0] - chSelTrigPosMovAve, 0, nSamples - chSelTrigPosMovAve );
    channelConfigTable.setInt(posTrigNew, chSelected, "post.tr");
  } else if ( roiMinLineWidth == 2 ) {
    float[] value = plot.getValueAt(mouseX, mouseY);
    int roiMinNew = constrain( (int)value[0], 0, channelConfigTable.getInt(chSelected, "roi.max") - 1  );
    channelConfigTable.setInt(roiMinNew, chSelected, "roi.min");
  } else if ( roiMaxLineWidth == 2 ) {
    float[] value = plot.getValueAt(mouseX, mouseY);
    int roiMaxNew = constrain( (int)value[0], channelConfigTable.getInt(chSelected, "roi.min") + 1, integralHistoNBins );
    channelConfigTable.setInt(roiMaxNew, chSelected, "roi.max");
  }
}

void mousePressed() {
  if ( bnStartStop.getText() == "Stop" && trigLineWidth == 2 ) {
    swStopAcquisition();
  }
}

void mouseReleased() {
  if ( bnStartStop.getText() == "Stop" && trigLineWidth == 2 ) {
    swStartAcquisition();  // the digitizer automatically runs a clear cycle when an acquisition starts
  }
}


void keyPressed() {
  if ( (key == CODED) && !saveToFileIsEnabled ) {

    if (keyCode == UP || keyCode == DOWN) {

      if (waveformPlotIsEnabled) {

        if (saveToFileIsEnabled) {
          JOptionPane.showMessageDialog(null, "Can't change DC offset when save to file is enabled");
          return;
        }

        int chSelectedDcOffset = getChannelDCOffset(chSelected);
        if ( chSelectedDcOffset != -1 ) {
          swStopAcquisition();
          float[] yLims = plot.getYLim();
          float delta = abs( yLims[1] - yLims[0] );
          delta = round(delta / 40);

          if (keyCode == UP) chSelectedDcOffset += delta;
          else if (keyCode == DOWN) chSelectedDcOffset -= delta;
          chSelectedDcOffset = constrain( chSelectedDcOffset, 0, adcNChannels-1);
          println("delta = " + delta);
          println("offset = " + chSelectedDcOffset);
          channelConfigTable.setInt(chSelectedDcOffset, chSelected, "offset");  // update channelConfigTable
          setChannelDCOffset(chSelected, chSelectedDcOffset);  // set DC offset for chSelected

          int chSelectedTrigThres = getChannelTriggerThreshold(chSelected);
          if ( chSelectedTrigThres != -1 ) {
            if (keyCode == UP) chSelectedTrigThres += delta;
            else if (keyCode == DOWN) chSelectedTrigThres -= delta;
            chSelectedTrigThres = constrain( chSelectedTrigThres, 0, adcNChannels-1 );
            //println("chSelectedTrigThres = " + chSelectedTrigThres);
            channelConfigTable.setInt(chSelectedTrigThres, chSelected, "thres");
            setChannelTriggerThreshold(chSelected, chSelectedTrigThres);
          }
          //clearData();  // clear the data stored in the buffers of the digitizer
          //swStopAcquisition();
          //swStartAcquisition();  // the digitizer automatically runs a clear cycle when an acquisition starts
          stopDigitizer();
          startDigitizer();
          chSelTrigPosMovAveIsValid = false;
        }  // if ( chSelectedDcOffset != -1 )
      }  // if (waveformPlotIsEnabled)
    }  // if (keyCode == UP || keyCode == DOWN)


    if (keyCode == LEFT || keyCode == RIGHT) {

      if (waveformPlotIsEnabled) {

        if (saveToFileIsEnabled) {
          JOptionPane.showMessageDialog(null, "Can't change horizontal position when save to file is enabled");
          return;
        }

        if ( !modelName.equals("DT5743") ) {
          postTrigPercent = getPostTriggerSize();
          if ( postTrigPercent != -1 ) {
            if ( modelName.equals("DT5725") ) postTrigPercent /=2;  // fix error in CAEN_DGTZ_GetPostTriggerSize()
            if (keyCode == LEFT) postTrigPercent += 10;
            else postTrigPercent -= 10;
            //println("new postTrigPercent = " + postTrigPercent);
            postTrigPercent = constrain( postTrigPercent, 0, 100 );
            setPostTriggerSize(postTrigPercent);
            globalConfigTable.setInt(postTrigPercent, "postTrigPercent", 0);
          }  // if ( postTrigPercent != -1 )
        }  // if ( !modelName.equals("DT5743") )
        else {  // if ( modelName.equals("DT5743") )
          samPostTrigSize = getSAMPostTriggerSize(chSelected/2);  // SamIndex = chSelected/2
          if ( samPostTrigSize != -1 ) {
            if (keyCode == LEFT) samPostTrigSize += 10;
            else samPostTrigSize -= 10;
            samPostTrigSize = constrain( samPostTrigSize, 1, 255 );
            int samIndex = chSelected/2;
            setSAMPostTriggerSize(samIndex, samPostTrigSize);
            switch(samIndex) {
            case 0:
              globalConfigTable.setInt(samPostTrigSize, "DT5743PostTrigSize_ch0-ch1_", 0);
              break;
            case 1:
              globalConfigTable.setInt(samPostTrigSize, "DT5743PostTrigSize_ch2-ch3_", 0);
              break;
            case 2:
              globalConfigTable.setInt(samPostTrigSize, "DT5743PostTrigSize_ch4-ch5_", 0);
              break;
            case 3:
              globalConfigTable.setInt(samPostTrigSize, "DT5743PostTrigSize_ch6-ch7_", 0);
              break;
            default:
            }
          }  // if ( samPostTrigSize != -1 )
        }  // if ( modelName.equals("DT5743") )

        //swStopAcquisition();
        //swStartAcquisition();  // the digitizer automatically runs a clear cycle when an acquisition starts
        stopDigitizer();
        startDigitizer();
        chSelTrigPosMovAveIsValid = false;
      }  // if (waveformPlotIsEnabled)
      else if (integralHistoPlotIsEnabled) {

        if (saveToFileIsEnabled) {
          JOptionPane.showMessageDialog(null, "Can't change histogram scale when save to file is enabled");
          return;
        }

        int integralHistoScale = channelConfigTable.getInt(chSelected, "hist.scale");
        int roiMin = channelConfigTable.getInt(chSelected, "roi.min");
        int roiMax = channelConfigTable.getInt(chSelected, "roi.max");

        if (keyCode == LEFT) {
          integralHistoScale = integralHistoScale * 2;
          roiMin = roiMin / 2;
          if (roiMax != integralHistoNBins) roiMax = roiMax / 2;
        } else if (integralHistoScale >= 2) {
          integralHistoScale = max( integralHistoScale / 2, 2 );
          roiMin = min( roiMin * 2, timeHistoNBins - 2 );
          roiMax = min( roiMax * 2, timeHistoNBins );
        }

        channelConfigTable.setInt(integralHistoScale, chSelected, "hist.scale");
        channelConfigTable.setInt(roiMin, chSelected, "roi.min");
        channelConfigTable.setInt(roiMax, chSelected, "roi.max");
      }  // else if (integralHistoPlotIsEnabled)
    }  // if (keyCode == LEFT || keyCode == RIGHT)
  }  // if ( (key == CODED) && !saveToFileIsEnabled )

  // Don't close Processing when ESC key is pressed.
  if (keyCode == ESC) key = 0;

  // pause - unpause plot with SPACE key
  if (key == ' ') {
    plotIsPaused = !plotIsPaused;
    println("plotIsPaused = " + plotIsPaused);
  }

  // pause - unpause autotrigger with A key
  if (key == 'a') {
    autoTrigIsEnabled = !autoTrigIsEnabled;
    println("autoTrigIsEnabled = " + autoTrigIsEnabled);
  }

  // for 2D histo only
  if (twoDPlotIsEnabled) {
    if (key == '+') plot.fillScale *= 1.5;
    if (key == '-') plot.fillScale /= 1.5;
  }

  // make channel config table visible
  if (key == 'c') frameChConfig.setVisible(true);

  // make global config table visible
  if (key == 'g') frameGlConfig.setVisible(true);
}


//void keyTyped() {
//  if (key == 'p') {
//    // change polarity for all channels
//    int pol = getChannelPulsePolarity(0);  // get ch0 pulse polarity (ch1 - ch3 are the same)
//    if (pol != -1) {
//      if (pol == PulsePolarity_t.pulsePolarityPos) pol = PulsePolarity_t.pulsePolarityNeg;
//      else pol = PulsePolarity_t.pulsePolarityPos;
//      for (int ch=0; ch < boardInfoStruct.Channels; ch++) {
//        setChannelPulsePolarity(ch, pol);  // set pulse polarity for a specific channel
//        println(ch + " pol = " + pol);
//        getChannelPulsePolarity(ch);
//      }
//    }
//  }
//}



// geomerative library
void drawRectangle(GPointsArray rectPoints, int polygonColor) {
  GPointsArray plotRectPoints = plot.mainLayer.valueToPlot(rectPoints);

  float x = plotRectPoints.getX(0);
  float y = plotRectPoints.getY(0);
  float w = plotRectPoints.getX(2) - plotRectPoints.getX(0);
  float h = plotRectPoints.getY(1) - plotRectPoints.getY(0);
  RShape r1 = RG.getRect(x, y, w, h);
  fill(polygonColor);
  //r1.draw();

  x = 0;
  y = 0;
  w = plot.dim[0];
  h = -plot.dim[1];
  RShape r2 = RG.getRect(x, y, w, h);
  //r2.draw();

  RShape r3 = r1.intersection(r2);
  r3.draw();
}


//void drawLegend() {
//  if ( plot.layerList.size() != nChannels ) return;

//  String[] text = {"", "ch0", "ch1", "ch2", "ch3"};
//  for (int ch=0; ch < nChannels; ch++) {
//    int aux = channelEnableMask & (1 << ch);
//    if ( aux == 0) text[ch+1] = "";
//  }
//  float[] xRelativePos = {.97, .97, .97, .97, .97};
//  float[] yRelativePos = {.97, .97, .92, .87, .82};
//  plot.drawLegend(text, xRelativePos, yRelativePos);
//}



// https://discourse.processing.org/t/sketch-does-not-always-have-focus-on-start-up/16834
// @rhole ( Richard L Hole )
//__ processing sketch need to have FOCUS to detect a key press
//__ so usually we click with mouse on canvas after start, to allow keyboard
//__ as like on WIN10 30% at start there is NO focus
//__ but this code seems to work very good
boolean _focusConfirmed = false; //__ if false --> force set focus

void check_focus() {
  if ( !_focusConfirmed ) { //&& millis() < 20000 ) {
    if ( !focused ) ((java.awt.Canvas) surface.getNative()).requestFocus();
    else            _focusConfirmed= true;
    //println("focus_check: time " + millis() + "ms");
    //consolFile.println("focus_check: time " + millis() + "ms");
  }
}



void clearMainLayer() {
  int nPoints = plot.getMainLayer().getPoints().getNPoints();
  for (int i = nPoints-1; i >= 0; i--) {
    plot.getMainLayer().removePoint(i);
  }
}




// Load matrix from file
int[][] loadMatCSV(String fileName) {
  String lines[] = loadStrings(fileName);
  int nHeaderLines = 0;
  boolean endOfHeader = false;
  while ( !endOfHeader ) {
    String[] sa = splitTokens( lines[nHeaderLines], ", " );
    if ( sa.length == 0 ) {
      //println(nHeaderLines + ": " + lines[nHeaderLines] );
      nHeaderLines++;
      continue;
    } else if ( !isInteger(sa[0]) ) {
      //println(nHeaderLines + ": " + lines[nHeaderLines] );
      nHeaderLines++;
      continue;
    }
    endOfHeader = true;
  }
  int nRows = lines.length - nHeaderLines;
  int[][] x = new int[nRows][];
  for (int i=0; i<x.length; i++) {
    x[i] = int(splitTokens(lines[i + nHeaderLines]));
  }
  return x;
}

// https://stackoverflow.com/questions/237159/whats-the-best-way-to-check-if-a-string-represents-an-integer-in-java
public static boolean isInteger(String str) {
  if (str == null) return false;
  int length = str.length();
  if (length == 0) return false;
  int i = 0;
  if (str.charAt(0) == '-') {
    if (length == 1) return false;
    i = 1;
  }
  for (; i < length; i++) {
    char c = str.charAt(i);
    if (c < '0' || c > '9') return false;
  }
  return true;
}

/*
void detectWindowResizeThread() {
 delay(3000);
 int w = width;
 int h = height;
 while (true) {
 if (w != width || h != height) {
 // Sketch window has been resized
 println("Sketch window has been resized");
 plot.setOuterDim( plot.defaultOuterDim );
 opWaveform.moveTo( opWaveform.getX(), height - 25 );
 opIntegralHisto.moveTo( opIntegralHisto.getX(), height - 25 );
 if (serIsEnabled) {
 opTimeHisto.moveTo( opTimeHisto.getX(), height - 25 );
 op2d.moveTo( op2d.getX(), height - 25 );
 }
 w = width;
 h = height;
 //loop();
 }
 // GUI elements need redraw
 delay(100);
 //loop();  // another windowResized() thread in GPlotD already does this
 }
 }
 */

//code to run on exit
void exit() {
  stopDigitizer();
  disconnect();
  updateConfigFile();

  if (saveToFileIsEnabled) {
    if (serIsEnabled) {
      serOutFile.flush();  // Writes the remaining data to the file
      serOutFile.close();  // Finishes the file
    } else
      for (int ch=0; ch < nChannels; ch++) {
        int aux = channelEnableMask & (1 << ch);
        if ( aux != 0) {
          chOutFiles[ch].flush();  // Writes the remaining data to the file
          chOutFiles[ch].close();  // Finishes the file
        }
      }
  }

  println("exiting");
  consolFile.println("exiting");
  consolFile.flush();  // Writes the remaining data to the file
  consolFile.close();  // Finishes the file
  super.exit();
}


void stopDigitizer() {
  readWformThreadIsEnabled = false;
  swStopAcquisition();
  freeEvent();  // This function releases the event memory buffer allocated by either the DecodeEvent or AllocateEvent function.
  while (readWformThreadIsBusy) delay(100);
  freeReadoutBuffer();
}
