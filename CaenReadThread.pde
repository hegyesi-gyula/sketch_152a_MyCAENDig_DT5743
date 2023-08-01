int prevPlotTime = 0;
int prevEventTime = 0;  // for auto trigger if save to file is not enabled
int prevEventCounter = 0;
int prevEventSavedCounter = 0;
short [][] samples;
float [][] samplesX743;
int nSamples = 0;
int integralHistoNBins = 100;
float [][] integralHistos;
int timeHistoScale;
int timeHistoNBins = 100;
float [] timeHisto = new float [timeHistoNBins];
int [][] colorMap;
int [][] suniMatrix = new int [timeHistoNBins][integralHistoNBins];
int chTrigPos = 0;
int [] chTrigPoss;
int chSelTrigPosMovAve = 0;  // to fix trigger jitter
boolean chSelTrigPosMovAveIsValid = false;
int chSelTrigPos = 0;  // to fix trigger jitter
boolean clearIntegralHistos = false;
long triggerTimeTag;
int [] chIntegrals;

void readWformThread() {
  //println("in readWformThread");
  int prevT;  // debug

  samples = new short [nChannels][];
  samplesX743 = new float [nChannels][];
  integralHistos = new float [nChannels][integralHistoNBins];
  timeHistoScale = recordLength / timeHistoNBins;
  chIntegrals = new int [nChannels]; // default values are all 0
  chTrigPoss = new int [nChannels]; // default values are all 0

  // Load color map matrix from file
  //colorMap = loadMatCSV("ncview_default.ncmap");
  //colorMap = loadMatCSV("rainbow.gp");
  colorMap = loadMatCSV("BkBlAqGrYeOrReViWh200.rgb");

  IntList chSelTrigPosList = new IntList();
  int chSelTrigPosListSize = 100;
  for (int i = 0; i < chSelTrigPosListSize; i++) chSelTrigPosList.append(0);
  int trigPosSum = 0;

  while (true) {
    //for (int n = 0; n < 33; n++) {  // debug
    delay(1);  // reduces CPU usage at low input rates
    if (!readWformThreadIsEnabled) continue;  // inactivate thread between a stopDigitizer() startDigitizer() call pair after key events

    readWformThreadIsBusy = true;

    if (clearIntegralHistos) {
      integralHistos = new float [nChannels][integralHistoNBins];
      clearIntegralHistos = false;
    }

    //print("=");
    //prevT = millis();
    readDataFromDigitizer();  // this function performs a block transfer of data from the digitizer to the computer
    numEvents = getNumEvents();
    //println("Number of Events: " + numEvents);  // debug
    //consolFile.println("Number of Events: " + numEvents);

    //if (numEvents != 0) println(getTimeStampForFilename() + "\ntransferDataBuffer: " + (millis()-prevT));

    for (int i=0; i<numEvents; i++) {

      // this array is overkill but kept for any future requests
      boolean [] chIntegralIsInRoi = new boolean [nChannels]; // default values are all false
      int multiplicity = 0;
      prevEventTime = millis();

      // break from loop when exiting
      if (!readWformThreadIsEnabled) break;

      //allocateEvent();
      EventInfo_t eventInfoStruct = getEventInfo(i);
      if (eventInfoStruct == null) break;
      //while (eventInfoStruct == null) {
      //  println("eventInfoStruct == null");
      //  println(numEvents, i);
      //  delay(1000);
      //  eventInfoStruct = getEventInfo(i);
      //}
      eventCounter = eventInfoStruct.eventCounter;
      if (globalConfigTable.getValueAt("timestamp", 0).equals("caen") )
        triggerTimeTag = eventInfoStruct.triggerTimeTag & 0xFFFFFFFFL; // 32 bit unsigned to long
      else
        triggerTimeTag = millis() / 1000;

      //chMask = eventInfoStruct.channelMask;

      UINT16_EVENT_t eventStruct = null;
      CAEN_DGTZ_X743_EVENT1_t eventStructX743 = null;
      //prevT = millis();
      if ( !modelName.equals("DT5743") ) {
        eventStruct = decodeEvent();
        //println("after UINT16_EVENT_t eventStruct = decodeEvent();");
      } else {
        //println("before CAEN_DGTZ_X743_EVENT_t eventStructX743 = decodeX743Event();");
        //delay(1000);
        //exit();
        //readWformThreadIsEnabled = false;
        eventStructX743 = decodeX743Event1();
      }
      //println("decodeEvent: " + (millis()-prevT));
      //println("after CAEN_DGTZ_X743_EVENT_t eventStructX743 = decodeX743Event();");

      //------------------------------------------------------------------------------------------
      // for each channel:
      // get waveform
      // find trigger position
      // calculate baseline
      // calculate pulse integral
      // if scaled integral is within ROI, increment multiplicity and integral histo
      // if SER is enabled process SER pulses
      //------------------------------------------------------------------------------------------
      for (int ch=0; ch < nChannels; ch++) {

        // if channel is not enabled skip the remainder of the block and start the next iteration (next channel)
        int aux = channelEnableMask & (1 << ch);
        if (aux == 0) {
          // dummy samples to preserve waveform colors in the plot
          samples[ch] = new short [1];
          samples[ch][0] = 0;
          continue;
        }


        // get samples of this channel in an array of shorts
        Pointer samplesPointer = null;
        if ( !modelName.equals("DT5743") ) {
          nSamples = eventStruct.ChSize[ch];
          samplesPointer = eventStruct.DataChannel[ch];
          if (samplesPointer == null) continue;  // fontos!
          // com.sun.jna.Pointer: getShortArray(long offset, int arraySize)
          // Read a native array of int16 of size arraySize from the given offset from this Pointer.
          samples[ch] = samplesPointer.getShortArray(0, nSamples);
        }  // if ( !modelName.equals("DT5743") )
        else {  //if ( modelName.equals("DT5743") )
          int groupCh = ch % 2;
          byte[] grPresent = eventStructX743.GrPresent;
          if ( ch == 0 || ch == 1 ) {
            if ( grPresent[0] == 1 ) {
              nSamples = eventStructX743.ChSize01;
              samplesPointer = eventStructX743.DataChannel01[groupCh];
            }
          }  // if ( ch == 0 || ch == 1 )
          else if ( ch == 2 || ch == 3 ) {
            if ( grPresent[1] == 1 ) {
              nSamples = eventStructX743.ChSize23;
              samplesPointer = eventStructX743.DataChannel23[groupCh];
            }
          }  // else if ( ch == 2 || ch == 3 )
          else if ( ch == 4 || ch == 5 ) {
            if ( grPresent[2] == 1 ) {
              nSamples = eventStructX743.ChSize45;
              samplesPointer = eventStructX743.DataChannel45[groupCh];
            }  // else if ( ch == 4 || ch == 5 )
          }  // else if ( ch == 4 || ch == 5 )
          else if ( ch == 6 || ch == 7 ) {
            if ( grPresent[3] == 1 ) {
              nSamples = eventStructX743.ChSize67;
              samplesPointer = eventStructX743.DataChannel67[groupCh];
            }
          }  // else if ( ch == 6 || ch == 7 )

          if (samplesPointer == null) continue;  // fontos!
          // com.sun.jna.Pointer: getFloatArray(long offset, int arraySize)
          // Read a native array of float of size arraySize from the given offset from this Pointer.
          samplesX743[ch] = samplesPointer.getFloatArray(0, nSamples);
          samples[ch] = new short [nSamples];
          for (int j=0; j<nSamples; j++) {
            samples[ch][j] = (short)( samplesX743[ch][j] + 2048 );  // map bipolar (-2048 to 2047) float to unipolar (0 to 4095) short
          }
          //}
        }  // if ( modelName.equals("DT5743") )


        //println("nSamples: " + nSamples);
        //println("samplesPointer: " + samplesPointer);
        //prevT = millis();
        //samples[ch] = samplesPointer.getShortArray(0, nSamples);
        //println("getShortArray: " + (millis()-prevT));
        //prevT = millis();

        //readWformThreadIsEnabled = false;
        //if (!readWformThreadIsEnabled) break;


        // find channel trig position
        // if ch0 trig. is common, use ch0 trig. pos. for other channels
        if ( ch == 0 || globalConfigTable.getValueAt("ch0TrigIsCommon", 0).equals("no") ) {
          chTrigPoss[ch] = -1;
          int j = 0;
          int thres = channelConfigTable.getInt(ch, "thres");
          boolean overThres = false;
          boolean overThresPrev = true;  // true prevents false triger at j = 0
          while (j < nSamples) {
            if ( channelConfigTable.getValueAt(ch, "tr.pol").equals("pos") )
              overThres = samples[ch][j] > thres;
            else
              overThres = samples[ch][j] < thres;
            if ( !overThresPrev && overThres ) {
              chTrigPoss[ch] = j;
              break;
            }
            overThresPrev = overThres;
            j++;
          }
        }  // found channel trig position (if not, then chTrigPos is still -1)
        else chTrigPoss[ch] = chTrigPoss[0];  // ch0 trig. is common so use ch0 trig. pos. for other channels

        if (ch == chSelected) chSelTrigPos = chTrigPoss[ch];

        // if chTrigPos is still -1 skip remainder of the block and start the next iteration (next channel)
        if (chTrigPoss[ch] == -1) continue;  // skip remainder of the block and start the next iteration (next channel)


        //println( "chTrigPos[" + ch + "] " +  chTrigPos);  // debug


        // create a fixed trig position for waveform display
        if (ch == chSelected) {
          //chSelTrigPos = chTrigPoss[ch];
          if ( abs(chSelTrigPos - chSelTrigPosMovAve) > 30 ) chSelTrigPosMovAveIsValid = false;  //
          if ( !chSelTrigPosMovAveIsValid ) {
            // clear moving average memory, init with new chSelTrigPos
            for (int j = 0; j < chSelTrigPosListSize; j++)
              chSelTrigPosList.set(j, chSelTrigPos);
            trigPosSum = chSelTrigPosListSize * chSelTrigPos;
            chSelTrigPosMovAveIsValid = true;
          }
          // moving average (Gaja)
          trigPosSum = trigPosSum - chSelTrigPosList.get(0) + chSelTrigPos;
          chSelTrigPosList.remove(0);
          chSelTrigPosList.append(chSelTrigPos);
          chSelTrigPosMovAve = trigPosSum / chSelTrigPosListSize;
        }


        // if baseline is invalid skip remainder of the block and start the next iteration (next channel)
        int chPreTrigPos = chTrigPoss[ch] - channelConfigTable.getInt(ch, "pre.tr");
        boolean baselineIsValid = chPreTrigPos > 0;
        if (!baselineIsValid) continue;


        // baseline is valid, so process samples
        // get baseline from max 1000 samples before (chTrigPos - pre.tr)
        int baselineIndexMin = max( 0, chPreTrigPos-1000);
        double baseLine = 0;
        int nBaselinePoints = 0;
        for (int k = baselineIndexMin; k < chPreTrigPos; k++) {
          baseLine += samples[ch][k];
          nBaselinePoints++;
        }
        baseLine /= nBaselinePoints;
        //println( "baseLine[" + str(ch) + "] " +  baseLine);  // debug


        // calculate integral of pulse
        double chIntegralD = 0;
        int chPostTrigPos = chTrigPoss[ch] + channelConfigTable.getInt(ch, "post.tr");
        chPostTrigPos = min( chPostTrigPos, nSamples );
        for (int k = chPreTrigPos; k < chPostTrigPos; k++) {
          if ( channelConfigTable.getValueAt(ch, "tr.pol").equals("pos") ) chIntegralD += samples[ch][k] - baseLine;
          else chIntegralD += baseLine - samples[ch][k];
        }
        chIntegrals[ch] = round( (float)chIntegralD );
        //println( "chIntegrals[" + str(ch) + "] " +  chIntegrals[ch]);  // debug

        if (!serIsEnabled) {
          int integralHistoIndex = chIntegrals[ch]/channelConfigTable.getInt(ch, "hist.scale");
          integralHistoIndex = constrain( integralHistoIndex, 0, integralHistoNBins - 1 );  // all overrange pulses will get the same integralHistoIndex --> integralHistoNBins - 1
          chIntegralIsInRoi[ch] =
            integralHistoIndex >= channelConfigTable.getInt(ch, "roi.min") &&
            integralHistoIndex <= channelConfigTable.getInt(ch, "roi.max");
          if (chIntegralIsInRoi[ch]) {
            multiplicity++;
            // increment integral histogram
            integralHistos[ch][integralHistoIndex]++;
          }
        }
        // if (serIsEnabled)
        else processSERPulses(baseLine, chPreTrigPos, chPostTrigPos);
      }  // for (int ch=0; ch < nChannels; ch++)




      //freeEvent();  // This function releases the event memory buffer allocated by either the DecodeEvent or AllocateEvent function.


      // if save to file is not enabled continue with the next iteration (next event)
      if (!saveToFileIsEnabled) continue;


      // if ser is enabled continue with the next iteration (next event)
      if (serIsEnabled) continue;


      // if event multiplicity is not enough continue with the next iteration (next event)
      if ( multiplicity < globalConfigTable.getInt("multiplicity", 0) ) continue;


      // save to file IS enabled and
      // ser IS NOT enabled and
      // event multiplicity IS enough
      // if we get here
      eventSavedCounter++;
      for (int ch=0; ch < nChannels; ch++) {
        int aux = channelEnableMask & (1 << ch);
        if ( aux == 0) continue;

        // create header of channel event
        chOutFiles[ch].println("-111111");
        chOutFiles[ch].println(eventCounter);
        chOutFiles[ch].println(triggerTimeTag);
        chOutFiles[ch].println(chIntegrals[ch]);
        chOutFiles[ch].println(chTrigPoss[ch]);
        //println();
        //println("-111111");
        //println(eventCounter);
        //println(triggerTimeTag);
        //println(mainPulseIntegral[ch]);
        //println(mainPulseTrigPos);
        for (int l=0; l<nSamples; l++) chOutFiles[ch].println( samples[ch][l] );
      }
    }  // for (int i=0; i<numEvents; i++)


    // auto trigger if save to file is not enabled
    if (!saveToFileIsEnabled && autoTrigIsEnabled) {
      if ( millis() - prevEventTime > 1000 * globalConfigTable.getInt("autoTrigSec", 0) ) {
        //println( "software trigger");  // debug
        sendSWtrigger();
      }
    }

    // each 0.5s flush output files, update event rate and plots
    if ( millis() - prevPlotTime > 500 ) {
      //if ( millis() - prevPlotTime > 500 || trigLineWidth == 2) {
      housekeeping();
    }

    readWformThreadIsBusy = false;
  }  // while (readWformThreadIsEnabled)
}  // void readWformThread()






// each 0.5s flush output files, update event rate and plots
void housekeeping() {

  // regularly flush output files
  consolFile.flush();  // Writes the remaining data to the file
  if (saveToFileIsEnabled) {
    if (serIsEnabled) {
      serOutFile.flush();  // Writes the remaining data to the file
    } else
      for (int ch=0; ch < nChannels; ch++) {
        int aux = channelEnableMask & (1 << ch);
        if ( aux != 0) {
          chOutFiles[ch].flush();  // Writes the remaining data to the file
        }
      }
  }

  // calculate event rate ( displayed in draw() )
  eventRate = (eventCounter - prevEventCounter) * 1000.0 / ( millis() - prevPlotTime );
  prevEventCounter = eventCounter;
  // calculate saved event rate ( displayed in draw() )
  eventSavedRate = (eventSavedCounter - prevEventSavedCounter) * 1000.0 / ( millis() - prevPlotTime );
  prevEventSavedCounter = eventSavedCounter;
  prevPlotTime = millis();
  //println(chTrigPos, chTrigPosMax);  // debug


  // update data for plots
  if (!plotIsPaused && eventCounter > -1) {

    readWformThreadModPlotReq = true;
    while (!readWformThreadModPlotAcq) delay(10);
    plot.clear();
    if (waveformPlotIsEnabled) {
      int jitter = 0;
      if (chSelTrigPos != -1) jitter = chSelTrigPosMovAve - chSelTrigPos;
      //println(chSelTrigPosMovAve);  // debug
      //println(jitter);  // debug

      int [][] waveform = new int [nChannels][];
      for (int ch=0; ch < nChannels; ch++) {

        float [] x = new float [samples[ch].length];
        for (int i = 0; i < x.length; i++) x[i] = i + jitter;

        waveform[ch] = new int [samples[ch].length];

        for (int l=0; l<samples[ch].length; l++) {
          waveform[ch][l] = samples[ch][l];
        }

        if ( samples[ch].length == 1 )  // dummy samples to preserve waveform colors in the plot
          plot.addLayer( float(waveform[ch]) );
        else
          plot.addLayer( x, float(waveform[ch]) );  // x.length IS allowed to be smaller than y.length
      }

      plot.getLayer( str(chSelected) ).setLineWidth(chSelectedLineWidth);
    } else if (integralHistoPlotIsEnabled) {
      plot.addLayer(integralHistos[chSelected], true);
    } else if (timeHistoPlotIsEnabled) {
      plot.addLayer(timeHisto, true);
    } else {
      plot.addHisto2D(suniMatrix, colorMap);
    }
    readWformThreadModPlotReq = false;
    loop();
  }  // if (!plotIsPaused && eventCounter > -1)
}  // void housekeeping()
