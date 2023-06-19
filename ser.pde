void processSERPulses(double baseLine, int chIndexPreTrig, int chIndexPostTrig) {
  // create header of ser event
  if (saveToFileIsEnabled) {
    serOutFile.println("-111111");
    serOutFile.println(eventCounter);
    serOutFile.println(triggerTimeTag);
    serOutFile.println(chIntegrals[0]);
    serOutFile.println(chTrigPoss[0]);
  }

  // now process SER pulses from nPointsPreSER to (nSamples - nPointsPostSER)
  int j = nPointsPreSER;

  while (j < nSamples - nPointsPostSER) {
    int serTrigPos = 0;

    // search for SER pulses only before and after the main pulse
    boolean serIsSafe =
      j < chIndexPreTrig - nPointsPostSER ||
      j > chIndexPostTrig + nPointsPreSER;

    // new SER pulse
    if ( serIsSafe && (baseLine - samples[0][j] > trigLevelSER) ) {

      // preserve SER trigger position in SERTrigPos
      serTrigPos = j;

      // calculate integral of SER pulse
      int serIntegral = 0;
      for (int k = j-nPointsPreSER; k < j+nPointsPostSER; k++) {
        if (k < nSamples)
          serIntegral += baseLine - samples[0][k];
      }
      //if (serIntegral < 47000)
      //println( "serIntegral " +  serIntegral);

      if (saveToFileIsEnabled) serOutFile.println(serIntegral);
      if (saveToFileIsEnabled) serOutFile.println(serTrigPos);  // SER pulse front index

      // increment SER integral histogram
      int serIntegralHistoIndex = serIntegral/channelConfigTable.getInt(16, "hist.scale");
      serIntegralHistoIndex = constrain( serIntegralHistoIndex, 0, integralHistos[0].length - 1 );  // all overrange pulses will get the same integralHistoIndex --> integralHisto[ch].length - 1
      if (serIntegralHistoIndex != integralHistos[0].length-1)  // do not count overrange pulses
        integralHistos[0][serIntegralHistoIndex]++;

      // increment time histogram
      //int timeHistoIndex = (serTrigPos - chTrigPos) / timeHistoScale;
      int timeHistoIndex = serTrigPos / timeHistoScale;
      timeHistoIndex = constrain( timeHistoIndex, 0, timeHisto.length - 1 );  // all overrange pulses will get the same timeHistoIndex --> timeHisto.length - 1
      if (timeHistoIndex != timeHisto.length-1)  // do not count overrange pulses
        timeHisto[timeHistoIndex]++;
      if (timeHistoIndex < suniMatrix.length-1 && serIntegralHistoIndex < suniMatrix[0].length-1)
        suniMatrix[timeHistoIndex] [serIntegralHistoIndex] ++;

      j += nPointsPostSER;  // continue searching after current SER pulse
    }  // if ( serIsSafe && (baseline - samples[ch][j] > trigLevelSER) )
    j++;
  }  // while (j < nSamples - nPointsPostSER)
}
