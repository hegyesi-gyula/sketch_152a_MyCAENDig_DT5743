// Need G4P library
import g4p_controls.*;


boolean waveformPlotIsEnabled = true;
boolean integralHistoPlotIsEnabled = false;
boolean timeHistoPlotIsEnabled = false;
boolean twoDPlotIsEnabled = false;
float [] waveformPlotXLim;
float [] waveformPlotYLim;

public void waveform_clicked1(GOption source, GEvent event) { //_CODE_:waveform:815172:
  // Set the plot title and the axis labels
  plot.setTitleText("Caen " + modelName + " waveforms");
  plot.getXAxis().setAxisLabelText("(" + timeUnit + ")");
  plot.getYAxis().setAxisLabelText("(ADC channel)");
  waveformPlotIsEnabled = true;
  integralHistoPlotIsEnabled = false;
  timeHistoPlotIsEnabled = false;
  twoDPlotIsEnabled = false;
  plot.pg = null;
  plot.suniMatrix = new int [1][1];
  // add corner points to main layer to get proper autoscale
  plot.getMainLayer().addPoints(points);
  plot.fixedXLim = false;
  plot.fixedYLim = false;
  plot.updateLimits();
  bnClearHisto.setVisible(false);
}

public void integralHisto_clicked1(GOption source, GEvent event) { //_CODE_:integralHisto:743536:
  // Set the plot title and the axis labels
  plot.setTitleText(" Pulse Integral Spectrum");
  plot.getXAxis().setAxisLabelText("Integral");
  plot.getYAxis().setAxisLabelText("Counts");
  waveformPlotIsEnabled = false;
  integralHistoPlotIsEnabled = true;
  timeHistoPlotIsEnabled = false;
  twoDPlotIsEnabled = false;
  plot.pg = null;
  plot.suniMatrix = new int [1][1];
  clearMainLayer();
  plot.fixedXLim = false;
  plot.fixedYLim = false;
  plot.updateLimits();
  bnClearHisto.setVisible(true);
}

public void timeHisto_clicked1(GOption source, GEvent event) { //_CODE_:timeHisto:898015:
  // Set the plot title and the axis labels
  plot.setTitleText(" Pulse Time Spectrum");
  plot.getXAxis().setAxisLabelText("Time");
  plot.getYAxis().setAxisLabelText("Counts");
  waveformPlotIsEnabled = false;
  integralHistoPlotIsEnabled = false;
  timeHistoPlotIsEnabled = true;
  twoDPlotIsEnabled = false;
  plot.pg = null;
  plot.suniMatrix = new int [1][1];
  clearMainLayer();
  plot.fixedXLim = false;
  plot.fixedYLim = false;
  plot.updateLimits();
}

void twoD_clicked(GOption source, GEvent event) {
  // Set the plot title and the axis labels
  plot.setTitleText(" Integral - Time ");
  plot.getXAxis().setAxisLabelText("Time");
  plot.getYAxis().setAxisLabelText("Integral");
  waveformPlotIsEnabled = false;
  integralHistoPlotIsEnabled = false;
  timeHistoPlotIsEnabled = false;
  twoDPlotIsEnabled = true;
  clearMainLayer();
  plot.fixedXLim = false;
  plot.fixedYLim = false;
  plot.updateLimits();
}

void opChClicked(GOption source, GEvent event) {
  for (int i=0; i < opCh.length; i++) {
    if (opCh[i].isSelected()) {
      println("ch" + i + " is selected");
      consolFile.println("ch" + i + " is selected");
      chSelected = i;
      chSelTrigPosMovAveIsValid = false;
      chSelTrigPosMovAve = chTrigPoss[chSelected];
      chSelTrigPos = chTrigPoss[chSelected];
      break;
    }
  }
}


void bnStartStop_eventHandler(GButton button, GEvent event) {
  // if button contains "Start"
  if (bnStartStop.getText() == "Start") {
    bnStartStop.setText("Stop");
    swStartAcquisition();
  }
  // if button contains "Stop"
  else {
    bnStartStop.setText("Start");
    swStopAcquisition();
  }
}


void bnClearHisto_eventHandler(GButton button, GEvent event) {
  clearIntegralHistos = true;
}

// Create all the GUI controls.
public void createGUI() {
  G4P.messagesEnabled(false);
  G4P.setGlobalColorScheme(GCScheme.BLUE_SCHEME);
  G4P.setMouseOverEnabled(false);
  tgPlot = new GToggleGroup();

  opWaveform = new GOption(this, 10, height - 25, 80, 20);
  opWaveform.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  opWaveform.setText("waveform");
  opWaveform.setOpaque(false);
  opWaveform.addEventHandler(this, "waveform_clicked1");
  tgPlot.addControl(opWaveform);
  opWaveform.setSelected(true);

  opIntegralHisto = new GOption(this, 90, height - 25, 110, 20);
  opIntegralHisto.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  opIntegralHisto.setText("integralHisto");
  if (serIsEnabled) opIntegralHisto.setText("SERintegralHisto");
  opIntegralHisto.setOpaque(false);
  opIntegralHisto.addEventHandler(this, "integralHisto_clicked1");
  tgPlot.addControl(opIntegralHisto);

  if (serIsEnabled) {
    opTimeHisto = new GOption(this, 210, height - 25, 80, 20);
    opTimeHisto.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
    opTimeHisto.setText("timeHisto");
    opTimeHisto.setOpaque(false);
    opTimeHisto.addEventHandler(this, "timeHisto_clicked1");
    tgPlot.addControl(opTimeHisto);

    op2d = new GOption(this, 290, height - 25, 120, 20);
    op2d.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
    op2d.setText("2dHisto");
    op2d.setOpaque(false);
    op2d.addEventHandler(this, "twoD_clicked");
    tgPlot.addControl(op2d);
  }

  GToggleGroup tgChannel = new GToggleGroup();
  opCh = new GOption[nChannels];
  for (int ch = 0; ch < opCh.length; ch++) {
    int gap = (ch / 4) * 10;
    //println(gap);
    opCh[ch] = new GOption(this, 10 + gap + 16*ch, 20, 15, 15);
    opCh[ch].addEventHandler(this, "opChClicked");
    opCh[ch].setOpaque(true);
    opCh[ch].setLocalColor( 6, plot.boyntonOptimized[ ch % plot.boyntonOptimized.length ] );
    int aux = channelEnableMask & (1 << ch);
    if ( aux == 0) {
      opCh[ch].setOpaque(false);
      opCh[ch].setEnabled(false);
    }
  }
  tgChannel.addControls(opCh);

  // select first enabled channel at startup
  for (int ch = 0; ch < nChannels; ch++) {
    int aux = channelEnableMask & (1 << ch);
    if ( aux != 0) {
      opCh[ch].setSelected(true);
      opChClicked(opCh[ch], GEvent.CLICKED);
      break;
    }
  }

  lbChannels = new GLabel(this, 10, 3, 260, 20);
  lbChannels.setText("channels");

  // Create start/stop button
  bnStartStop = new GButton(this, 10, 50, 37, 25, "Stop");
  bnStartStop.setLocalColor(4, #F5A465);  // background color = orange
  bnStartStop.addEventHandler(this, "bnStartStop_eventHandler");
  //bnStartStop.setEnabled(false);

  // Create ClearHisto button
  bnClearHisto = new GButton(this, 10, 80, 37, 25, "Clear");
  bnClearHisto.setLocalColor(4, #AEF3FA);  // background color = light blue
  bnClearHisto.setVisible(false);
  bnClearHisto.addEventHandler(this, "bnClearHisto_eventHandler");
}

// Variable declarations
GToggleGroup tgPlot;
GOption opWaveform;
GOption opIntegralHisto;
GOption opTimeHisto;
GOption op2d;
GLabel lbChannels;
GOption [] opCh;
GButton bnStartStop;
GButton bnClearHisto;
