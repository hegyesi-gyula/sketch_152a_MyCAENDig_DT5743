
/**
 * ##library.name##
 * ##library.sentence##
 * ##library.url##
 *
 * Copyright ##copyright## ##author##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 * 
 * @author      ##author##
 * @modified    ##date##
 * @version     ##library.prettyVersion## (##library.version##)
 */

//package grafica;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import processing.core.PApplet;
import processing.core.PConstants;
import processing.core.PFont;

/**
 * Axis class.
 * 
 * @author ##author##
 */
public class GAxis implements PConstants {
  // The parent Processing applet
  protected final PApplet parent;

  // General properties
  protected final int type;
  protected float[] dim;
  protected float[] lim;
  protected boolean log;

  // Format properties
  protected float offset;
  protected int lineColor;
  protected float lineWidth;

  // Ticks properties
  protected int nTicks;
  protected float ticksSeparation;
  protected ArrayList<Float> ticks;
  protected ArrayList<Float> plotTicks;
  protected ArrayList<Boolean> ticksInside;
  protected ArrayList<String> tickLabels;
  protected boolean fixedTicks;
  protected float tickLength;
  protected float smallTickLength;
  protected boolean expTickLabels;
  protected boolean rotateTickLabels;
  protected boolean drawTickLabels;
  protected float tickLabelOffset;

  // Label properties
  protected final GAxisLabel lab;
  protected boolean drawAxisLabel;

  // Text properties
  protected String fontName;
  protected int fontColor;
  protected int fontSize;
  protected PFont font;

  /**
   * GAxis constructor
   * 
   * @param parent the parent Processing applet
   * @param type the axis type. It can be X, Y, TOP or RIGHT
   * @param dim the plot box dimensions in pixels
   * @param lim the limits
   * @param log the axis scale. True if it's logarithmic
   */
  public GAxis(PApplet parent, int type, float[] dim, float[] lim, boolean log) {
    this.parent = parent;

    this.type = (type == X || type == Y || type == TOP || type == RIGHT) ? type : X;
    this.dim = dim.clone();
    this.lim = lim.clone();
    this.log = log;

    // Do some sanity checks
    if (this.log && (this.lim[0] <= 0 || this.lim[1] <= 0)) {
      PApplet.println("The limits are negative. This is not allowed in logarithmic scale.");
      PApplet.println("Will set them to (0.1, 10)");

      if (this.lim[1] > this.lim[0]) {
        this.lim[0] = 0.1f;
        this.lim[1] = 10f;
      } else {
        this.lim[0] = 10f;
        this.lim[1] = 0.1f;
      }
    }

    offset = 5;
    lineColor = color(0);
    lineWidth = 1;

    nTicks = 5;
    ticksSeparation = -1;
    ticks = new ArrayList<Float>(nTicks);
    plotTicks = new ArrayList<Float>(nTicks);
    ticksInside = new ArrayList<Boolean>(nTicks);
    tickLabels = new ArrayList<String>(nTicks);
    fixedTicks = false;
    tickLength = 3;
    smallTickLength = 2;
    expTickLabels = false;
    rotateTickLabels = (this.type == X || this.type == TOP) ? false : true;
    drawTickLabels = (this.type == X || this.type == Y) ? true : false;
    tickLabelOffset = 7;

    lab = new GAxisLabel(this.parent, this.type, this.dim);
    drawAxisLabel = true;

    fontName = "SansSerif.plain";
    fontColor = color(0);
    fontSize = 11;
    font = this.parent.createFont(fontName, fontSize);

    // Update the arrayLists
    updateTicks();
    updatePlotTicks();
    updateTicksInside();
    updateTickLabels();
    //println("GAxis constr."); //debug
  }

  /**
   * Calculates the optimum number of significant digits to use for a given number
   * 
   * @param number the number
   * 
   * @return the number of significant digits
   */
  protected int obtainSigDigits(float number) {
    return Math.round(-PApplet.log(0.5f * Math.abs(number)) / GPlot.LOG10);
  }

  /**
   * Rounds a number to a given number of significant digits
   * 
   * @param number the number to round
   * @param sigDigits the number of significant digits
   * 
   * @return the rounded number
   */
  protected float roundPlus(float number, int sigDigits) {
    return BigDecimal.valueOf(number).setScale(sigDigits, BigDecimal.ROUND_HALF_UP).floatValue();
  }

  /**
   * Adapts the provided array list to the new size
   * 
   * @param a the array list
   * @param n the new size of the array
   */
  protected void adaptSize(ArrayList<?> a, int n) {
    if (n > a.size()) {
      for (int i = a.size(); i < n; i++) {
        a.add(null);
      }
    } else if (n < a.size()) {
      a.subList(n, a.size()).clear();
    }
  }

  /**
   * Updates the axis ticks
   */
  protected void updateTicks() {
    if (log) {
      obtainLogarithmicTicks();
    } else {
      obtainLinearTicks();
    }
  }

  /**
   * Calculates the axis ticks for the logarithmic scale
   */
  protected void obtainLogarithmicTicks() {
    // Get the exponents of the first and last ticks in increasing order
    int firstExp, lastExp;

    if (lim[1] > lim[0]) {
      firstExp = PApplet.floor(PApplet.log(lim[0]) / GPlot.LOG10);
      lastExp = PApplet.ceil(PApplet.log(lim[1]) / GPlot.LOG10);
    } else {
      firstExp = PApplet.floor(PApplet.log(lim[1]) / GPlot.LOG10);
      lastExp = PApplet.ceil(PApplet.log(lim[0]) / GPlot.LOG10);
    }

    // Calculate the ticks
    int n = (lastExp - firstExp) * 9 + 1;
    adaptSize(ticks, n);

    for (int exp = firstExp; exp < lastExp; exp++) {
      float base = roundPlus(PApplet.exp(exp * GPlot.LOG10), -exp);

      for (int i = 0; i < 9; i++) {
        ticks.set((exp - firstExp) * 9 + i, (i + 1) * base);
      }
    }

    ticks.set(ticks.size() - 1, roundPlus(PApplet.exp(lastExp * GPlot.LOG10), -lastExp));
  }

  /**
   * Calculates the axis ticks for the linear scale
   */
  protected void obtainLinearTicks() {
    // Obtain the required precision for the ticks
    float step = 0;
    int sigDigits = 0;
    int nSteps = 0;
    int exp = 0;

    if (ticksSeparation > 0) {
      step = (lim[1] > lim[0]) ? ticksSeparation : -ticksSeparation;
      sigDigits = obtainSigDigits(step);

      while (roundPlus(step, sigDigits) - step != 0) {
        sigDigits++;
      }

      nSteps = PApplet.floor((lim[1] - lim[0]) / step);
    } else if (nTicks > 0) {
      step = (lim[1] - lim[0]) / nTicks;
      // begin hegyesi mod: map steps to 1Ex, 2Ex or 5Ex
      //println(frameCount + " ====="); // debug
      //println(step); // debug
      sigDigits = obtainSigDigits(step);
      step = roundPlus(step, sigDigits);

      if (step == 0 || Math.abs(step) > Math.abs(lim[1] - lim[0])) {
        sigDigits++;
        step = roundPlus((lim[1] - lim[0]) / nTicks, sigDigits);
      }
      //println(step); // debug

      step = (lim[1] - lim[0]) / nTicks;
      exp = PApplet.floor(PApplet.log(Math.abs(step)) / PApplet.log(10));
      float mantissa = step * pow(10, -exp);
      int step125;
      if (mantissa < 1.4) step125 = 1;
      else if (mantissa < 3.2) step125 = 2;
      else if (mantissa < 7) step125 = 5;
      else step125 = 10;
      step = step125 * pow(10, exp);
      //println(step); // debug
      //step = roundPlus((float)step, -exp);
      //println(step); // debug
      // end hegyesi mod: map steps to 1Ex, 2Ex or 5Ex

      nSteps = PApplet.floor((lim[1] - lim[0]) / step);
    }

    // Calculate the linear ticks
    if (nSteps > 0) {
      // Obtain the first tick
      float firstTick = lim[0] + ((lim[1] - lim[0]) - nSteps * step) / 2;
      //println("firstTick1: " + firstTick); // debug

      // begin hegyesi mod: keep zero axes
      //// Subtract some steps to be sure we have all
      //firstTick = roundPlus(firstTick - 2 * step, sigDigits);
      //println("firstTick2: " + firstTick); // debug

      //while ((lim[1] - firstTick) * (lim[0] - firstTick) > 0) {
      //  firstTick = roundPlus(firstTick + step, sigDigits);
      //println("firstTick: " + firstTick); // debug
      //}
      firstTick = roundPlus( PApplet.floor(firstTick / step) * step, sigDigits);
      //println("firstTick: " + firstTick); // debug
      // end hegyesi mod: keep zero axes

      // Calculate the rest of the ticks
      int n = PApplet.floor(Math.abs((lim[1] - firstTick) / step)) + 1;
      //println("n: " + n); // debug      
      adaptSize(ticks, n);
      ticks.set(0, firstTick);
      float pTick = firstTick;
      for (int i = 1; i < n; i++) {
        //ticks.set(i, roundPlus(ticks.get(i - 1) + step, sigDigits));
        float cTick = roundPlus(pTick + step, -exp);
        ;        
        ticks.set(i, cTick);
        //println(i + ": " + cTick); // debug 
        pTick = cTick;
      }
    } else {
      ticks.clear();
    }
  }

  /**
   * Updates the positions of the axis ticks in the plot reference system
   */
  protected void updatePlotTicks() {
    int n = ticks.size();
    adaptSize(plotTicks, n);
    float scaleFactor;

    if (log) {
      if (type == X || type == TOP) {
        scaleFactor = dim[0] / PApplet.log(lim[1] / lim[0]);
      } else {
        scaleFactor = -dim[1] / PApplet.log(lim[1] / lim[0]);
      }

      for (int i = 0; i < n; i++) {
        plotTicks.set(i, PApplet.log(ticks.get(i) / lim[0]) * scaleFactor);
      }
    } else {
      if (type == X || type == TOP) {
        scaleFactor = dim[0] / (lim[1] - lim[0]);
      } else {
        scaleFactor = -dim[1] / (lim[1] - lim[0]);
      }

      for (int i = 0; i < n; i++) {
        plotTicks.set(i, (ticks.get(i) - lim[0]) * scaleFactor);
      }
    }
  }

  /**
   * Updates the array that indicates which ticks are inside the axis limits
   */
  protected void updateTicksInside() {
    int n = ticks.size();
    adaptSize(ticksInside, n);

    if (type == X || type == TOP) {
      for (int i = 0; i < n; i++) {
        ticksInside.set(i, (plotTicks.get(i) >= 0) && (plotTicks.get(i) <= dim[0]));
      }
    } else {
      for (int i = 0; i < n; i++) {
        ticksInside.set(i, (-plotTicks.get(i) >= 0) && (-plotTicks.get(i) <= dim[1]));
      }
    }
  }

  /**
   * Updates the axis tick labels
   */
  protected void updateTickLabels() {
    int n = ticks.size();
    adaptSize(tickLabels, n);

    if (log) {
      for (int i = 0; i < n; i++) {
        float tick = ticks.get(i);

        if (tick > 0) {
          float logValue = PApplet.log(tick) / GPlot.LOG10;
          boolean isExactLogValue = Math.abs(logValue - Math.round(logValue)) < 0.0001;

          if (isExactLogValue) {
            logValue = Math.round(logValue);

            if (expTickLabels) {
              tickLabels.set(i, "1e" + (int) logValue);
            } else {
              if (logValue > -3.1 && logValue < 3.1) {
                tickLabels.set(i, (logValue >= 0) ? PApplet.str((int) tick) : PApplet.str(tick));
              } else {
                tickLabels.set(i, "1e" + (int) logValue);
              }
            }
          } else {
            tickLabels.set(i, "");
          }
        } else {
          tickLabels.set(i, "");
        }
      }
    } else {
      for (int i = 0; i < n; i++) {
        float tick = ticks.get(i);
        tickLabels.set(i, 
          (tick % 1 == 0 && Math.abs(tick) < 1e9) ? PApplet.str((int) tick) : PApplet.str(tick));
      }
    }
  }

  /**
   * Removes those axis ticks that are outside the axis limits
   * 
   * @return the ticks that are inside the axis limits
   */
  protected float[] removeOutsideTicks() {
    float[] validTicks = new float[ticksInside.size()];
    int counter = 0;

    for (int i = 0; i < ticksInside.size(); i++) {
      if (ticksInside.get(i)) {
        validTicks[counter] = ticks.get(i);
        counter++;
      }
    }

    return Arrays.copyOf(validTicks, counter);
  }

  /**
   * Removes those axis ticks in the plot reference system that are outside the axis limits
   * 
   * @return the ticks in the plot reference system that are inside the axis limits
   */
  protected float[] removeOutsidePlotTicks() {
    float[] validPlotTicks = new float[ticksInside.size()];
    int counter = 0;

    for (int i = 0; i < ticksInside.size(); i++) {
      if (ticksInside.get(i)) {
        validPlotTicks[counter] = plotTicks.get(i);
        counter++;
      }
    }

    return Arrays.copyOf(validPlotTicks, counter);
  }

  /**
   * Moves the axis limits
   * 
   * @param newLim the new axis limits
   */
  public void moveLim(float[] newLim) {
    if (newLim[1] != newLim[0]) {
      // Check that the new limit makes sense
      if (log && (newLim[0] <= 0 || newLim[1] <= 0)) {
        PApplet.println("The limits are negative. This is not allowed in logarithmic scale.");
      } else {
        lim[0] = newLim[0];
        lim[1] = newLim[1];

        // Calculate the new ticks if they are not fixed
        if (!fixedTicks) {
          int n = ticks.size();

          if (log) {
            obtainLogarithmicTicks();
          } else if (n > 0) {
            // Obtain the ticks precision and the tick separation
            float step = 0;
            int sigDigits = 0;

            if (ticksSeparation > 0) {
              step = (lim[1] > lim[0]) ? ticksSeparation : -ticksSeparation;
              sigDigits = obtainSigDigits(step);

              while (roundPlus(step, sigDigits) - step != 0) {
                sigDigits++;
              }
            } else {
              step = (n == 1) ? lim[1] - lim[0] : ticks.get(1) - ticks.get(0);
              sigDigits = obtainSigDigits(step);
              step = roundPlus(step, sigDigits);

              if (step == 0 || Math.abs(step) > Math.abs(lim[1] - lim[0])) {
                sigDigits++;
                step = (n == 1) ? lim[1] - lim[0] : ticks.get(1) - ticks.get(0);
                step = roundPlus(step, sigDigits);
              }

              step = (lim[1] > lim[0]) ? Math.abs(step) : -Math.abs(step);
            }

            // Obtain the first tick
            float firstTick = ticks.get(0) + step * PApplet.ceil((lim[0] - ticks.get(0)) / step);
            firstTick = roundPlus(firstTick, sigDigits);

            if ((lim[1] - firstTick) * (lim[0] - firstTick) > 0) {
              firstTick = ticks.get(0) + step * PApplet.floor((lim[0] - ticks.get(0)) / step);
              firstTick = roundPlus(firstTick, sigDigits);
            }

            // Calculate the rest of the ticks
            n = PApplet.floor(Math.abs((lim[1] - firstTick) / step)) + 1;
            adaptSize(ticks, n);
            ticks.set(0, firstTick);

            for (int i = 1; i < n; i++) {
              ticks.set(i, roundPlus(ticks.get(i - 1) + step, sigDigits));
            }
          }

          // Obtain the new tick labels
          updateTickLabels();
        }

        // Update the rest of the arrays
        updatePlotTicks();
        updateTicksInside();
      }
    }
  }

  /**
   * Draws the axis
   */
  public void draw() {
    switch (type) {
      case X:
        drawAsXAxis();
      break;
    case Y:
      drawAsYAxis();
      break;
    case TOP:
      drawAsTopAxis();
      break;
    case RIGHT:
      drawAsRightAxis();
      break;
    }

    if (drawAxisLabel)
      lab.draw();
  }

  /**
   * Draws the axis as an X axis
   */
  protected void drawAsXAxis() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.stroke(lineColor);
    parent.strokeWeight(lineWidth);
    parent.strokeCap(SQUARE);

    // Draw the ticks
    parent.line(0, offset, dim[0], offset);

    for (int i = 0; i < plotTicks.size(); i++) {
      if (ticksInside.get(i)) {
        if (log && tickLabels.get(i).equals("")) {
          parent.line(plotTicks.get(i), offset, plotTicks.get(i), offset + smallTickLength);
        } else {
          parent.line(plotTicks.get(i), offset, plotTicks.get(i), offset + tickLength);
        }
      }
    }

    // Draw the tick labels
    if (drawTickLabels) {
      if (rotateTickLabels) {
        parent.textAlign(RIGHT, CENTER);

        for (int i = 0; i < plotTicks.size(); i++) {
          if (ticksInside.get(i) && !tickLabels.get(i).equals("")) {
            parent.pushMatrix();
            parent.translate(plotTicks.get(i), offset + tickLabelOffset);
            parent.rotate(-HALF_PI);
            parent.text(tickLabels.get(i), 0, 0);
            parent.popMatrix();
          }
        }
      } else {
        parent.textAlign(CENTER, TOP);

        for (int i = 0; i < plotTicks.size(); i++) {
          if (ticksInside.get(i) && !tickLabels.get(i).equals("")) {
            parent.text(tickLabels.get(i), plotTicks.get(i), offset + tickLabelOffset);
          }
        }
      }
    }

    parent.popStyle();
  }

  /**
   * Draws the axis as a Y axis
   */
  protected void drawAsYAxis() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.stroke(lineColor);
    parent.strokeWeight(lineWidth);
    parent.strokeCap(SQUARE);

    // Draw the ticks
    parent.line(-offset, 0, -offset, -dim[1]);

    for (int i = 0; i < plotTicks.size(); i++) {
      if (ticksInside.get(i)) {
        if (log && tickLabels.get(i).equals("")) {
          parent.line(-offset, plotTicks.get(i), -offset - smallTickLength, plotTicks.get(i));
        } else {
          parent.line(-offset, plotTicks.get(i), -offset - tickLength, plotTicks.get(i));
        }
      }
    }

    // Draw the tick labels
    if (drawTickLabels) {
      if (rotateTickLabels) {
        parent.textAlign(CENTER, BOTTOM);

        for (int i = 0; i < plotTicks.size(); i++) {
          if (ticksInside.get(i) && !tickLabels.get(i).equals("")) {
            parent.pushMatrix();
            parent.translate(-offset - tickLabelOffset, plotTicks.get(i));
            parent.rotate(-HALF_PI);
            parent.text(tickLabels.get(i), 0, 0);
            parent.popMatrix();
          }
        }
      } else {
        parent.textAlign(RIGHT, CENTER);

        for (int i = 0; i < plotTicks.size(); i++) {
          if (ticksInside.get(i) && !tickLabels.get(i).equals("")) {
            parent.text(tickLabels.get(i), -offset - tickLabelOffset, plotTicks.get(i));
          }
        }
      }
    }

    parent.popStyle();
  }

  /**
   * Draws the axis as a TOP axis
   */
  protected void drawAsTopAxis() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.stroke(lineColor);
    parent.strokeWeight(lineWidth);
    parent.strokeCap(SQUARE);

    parent.pushMatrix();
    parent.translate(0, -dim[1]);

    // Draw the ticks
    parent.line(0, -offset, dim[0], -offset);

    for (int i = 0; i < plotTicks.size(); i++) {
      if (ticksInside.get(i)) {
        if (log && tickLabels.get(i).equals("")) {
          parent.line(plotTicks.get(i), -offset, plotTicks.get(i), -offset - smallTickLength);
        } else {
          parent.line(plotTicks.get(i), -offset, plotTicks.get(i), -offset - tickLength);
        }
      }
    }

    // Draw the tick labels
    if (drawTickLabels) {
      if (rotateTickLabels) {
        parent.textAlign(LEFT, CENTER);

        for (int i = 0; i < plotTicks.size(); i++) {
          if (ticksInside.get(i) && !tickLabels.get(i).equals("")) {
            parent.pushMatrix();
            parent.translate(plotTicks.get(i), -offset - tickLabelOffset);
            parent.rotate(-HALF_PI);
            parent.text(tickLabels.get(i), 0, 0);
            parent.popMatrix();
          }
        }
      } else {
        parent.textAlign(CENTER, BOTTOM);

        for (int i = 0; i < plotTicks.size(); i++) {
          if (ticksInside.get(i) && !tickLabels.get(i).equals("")) {
            parent.text(tickLabels.get(i), plotTicks.get(i), -offset - tickLabelOffset);
          }
        }
      }
    }

    parent.popMatrix();
    parent.popStyle();
  }

  /**
   * Draws the axis as a RIGHT axis
   */
  protected void drawAsRightAxis() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.stroke(lineColor);
    parent.strokeWeight(lineWidth);
    parent.strokeCap(SQUARE);

    parent.pushMatrix();
    parent.translate(dim[0], 0);

    // Draw the ticks
    parent.line(offset, 0, offset, -dim[1]);

    for (int i = 0; i < plotTicks.size(); i++) {
      if (ticksInside.get(i)) {
        if (log && tickLabels.get(i).equals("")) {
          parent.line(offset, plotTicks.get(i), offset + smallTickLength, plotTicks.get(i));
        } else {
          parent.line(offset, plotTicks.get(i), offset + tickLength, plotTicks.get(i));
        }
      }
    }

    // Draw the tick labels
    if (drawTickLabels) {
      if (rotateTickLabels) {
        parent.textAlign(CENTER, TOP);

        for (int i = 0; i < plotTicks.size(); i++) {
          if (ticksInside.get(i) && !tickLabels.get(i).equals("")) {
            parent.pushMatrix();
            parent.translate(offset + tickLabelOffset, plotTicks.get(i));
            parent.rotate(-HALF_PI);
            parent.text(tickLabels.get(i), 0, 0);
            parent.popMatrix();
          }
        }
      } else {
        parent.textAlign(LEFT, CENTER);

        for (int i = 0; i < plotTicks.size(); i++) {
          if (ticksInside.get(i) && !tickLabels.get(i).equals("")) {
            parent.text(tickLabels.get(i), offset + tickLabelOffset, plotTicks.get(i));
          }
        }
      }
    }

    parent.popMatrix();
    parent.popStyle();
  }

  /**
   * Sets the plot box dimensions information
   * 
   * @param xDim the new plot box x dimension
   * @param yDim the new plot box y dimension
   */
  public void setDim(float xDim, float yDim) {
    if (xDim > 0 && yDim > 0) {
      dim[0] = xDim;
      dim[1] = yDim;
      updatePlotTicks();
      lab.setDim(dim);
    }
  }

  /**
   * Sets the plot box dimensions information
   * 
   * @param newDim the new plot box dimensions information
   */
  public void setDim(float[] newDim) {
    setDim(newDim[0], newDim[1]);
  }

  /**
   * Sets the axis limits
   * 
   * @param newLim the new axis limits
   */
  public void setLim(float[] newLim) {
    if (newLim[1] != newLim[0]) {
      // Make sure the new limits makes sense
      if (log && (newLim[0] <= 0 || newLim[1] <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        lim[0] = newLim[0];
        lim[1] = newLim[1];

        if (!fixedTicks) {
          updateTicks();
          updateTickLabels();
        }

        updatePlotTicks();
        updateTicksInside();
      }
    }
  }

  /**
   * Sets the axis limits and the axis scale
   * 
   * @param newLim the new axis limits
   * @param newLog the new axis scale
   */
  public void setLimAndLog(float[] newLim, boolean newLog) {
    if (newLim[1] != newLim[0]) {
      // Make sure the new limits makes sense
      if (newLog && (newLim[0] <= 0 || newLim[1] <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        lim[0] = newLim[0];
        lim[1] = newLim[1];
        log = newLog;

        if (!fixedTicks) {
          updateTicks();
          updateTickLabels();
        }

        updatePlotTicks();
        updateTicksInside();
      }
    }
  }

  /**
   * Sets the axis scale
   * 
   * @param newLog the new axis scale
   */
  public void setLog(boolean newLog) {
    if (newLog != log) {
      log = newLog;

      // Check if the old limits still make sense
      if (log && (lim[0] <= 0 || lim[1] <= 0)) {
        PApplet.println("The limits are negative. This is not allowed in logarithmic scale.");
        PApplet.println("Will set them to (0.1, 10)");

        if (lim[1] > lim[0]) {
          lim[0] = 0.1f;
          lim[1] = 10f;
        } else {
          lim[0] = 10f;
          lim[1] = 0.1f;
        }
      }

      if (!fixedTicks) {
        updateTicks();
        updateTickLabels();
      }

      updatePlotTicks();
      updateTicksInside();
    }
  }

  /**
   * Sets the axis offset with respect to the plot box
   * 
   * @param newOffset the new axis offset
   */
  public void setOffset(float newOffset) {
    offset = newOffset;
  }

  /**
   * Sets the line color
   * 
   * @param newLineColor the new line color
   */
  public void setLineColor(int newLineColor) {
    lineColor = newLineColor;
  }

  /**
   * Sets the line width
   * 
   * @param newLineWidth the new line width
   */
  public void setLineWidth(float newLineWidth) {
    if (newLineWidth > 0) {
      lineWidth = newLineWidth;
    }
  }

  /**
   * Sets the approximate number of ticks in the axis. The actual number of ticks depends on the axis limits and the
   * axis scale
   * 
   * @param newNTicks the new approximate number of ticks in the axis
   */
  public void setNTicks(int newNTicks) {
    if (newNTicks >= 0) {
      nTicks = newNTicks;
      ticksSeparation = -1;
      fixedTicks = false;
      //println("nTicks: " + nTicks); //debug

      if (!log) {
        updateTicks();
        updatePlotTicks();
        updateTicksInside();
        updateTickLabels();
      }
    }
  }

  /**
   * Sets the separation between the ticks in the axis
   * 
   * @param newTicksSeparation the new ticks separation
   */
  public void setTicksSeparation(float newTicksSeparation) {
    ticksSeparation = newTicksSeparation;
    fixedTicks = false;

    if (!log) {
      updateTicks();
      updatePlotTicks();
      updateTicksInside();
      updateTickLabels();
    }
  }

  /**
   * Sets the axis ticks
   * 
   * @param newTicks the new axis ticks
   */
  public void setTicks(float[] newTicks) {
    fixedTicks = true;
    int n = newTicks.length;
    adaptSize(ticks, n);

    for (int i = 0; i < n; i++) {
      ticks.set(i, newTicks[i]);
    }

    updatePlotTicks();
    updateTicksInside();
    updateTickLabels();
  }

  /**
   * Sets the axis ticks labels
   * 
   * @param newTickLabels the new axis ticks labels
   */
  public void setTickLabels(String[] newTickLabels) {
    if (newTickLabels.length == tickLabels.size()) {
      fixedTicks = true;

      for (int i = 0; i < tickLabels.size(); i++) {
        tickLabels.set(i, newTickLabels[i]);
      }
    }
  }

  /**
   * Sets if the axis ticks are fixed or not
   * 
   * @param newFixedTicks true if the axis ticks should be fixed
   */
  public void setFixedTicks(boolean newFixedTicks) {
    if (newFixedTicks != fixedTicks) {
      fixedTicks = newFixedTicks;

      if (!fixedTicks) {
        updateTicks();
        updatePlotTicks();
        updateTicksInside();
        updateTickLabels();
      }
    }
  }

  /**
   * Sets the tick length
   * 
   * @param newTickLength the new tick length
   */
  public void setTickLength(float newTickLength) {
    tickLength = newTickLength;
  }

  /**
   * Sets the small tick length
   * 
   * @param newSmallTickLength the new small tick length
   */
  public void setSmallTickLength(float newSmallTickLength) {
    smallTickLength = newSmallTickLength;
  }

  /**
   * Sets if the ticks labels should be displayed in exponential form or not
   * 
   * @param newExpTickLabels true if the ticks labels should be in exponential form
   */
  public void setExpTickLabels(boolean newExpTickLabels) {
    if (newExpTickLabels != expTickLabels) {
      expTickLabels = newExpTickLabels;
      updateTickLabels();
    }
  }

  /**
   * Sets if the ticks labels should be displayed rotated or not
   * 
   * @param newRotateTickLabels true is the ticks labels should be rotated
   */
  public void setRotateTickLabels(boolean newRotateTickLabels) {
    rotateTickLabels = newRotateTickLabels;
  }

  /**
   * Sets if the ticks labels should be drawn or not
   * 
   * @param newDrawTicksLabels true it the ticks labels should be drawn
   */
  public void setDrawTickLabels(boolean newDrawTicksLabels) {
    drawTickLabels = newDrawTicksLabels;
  }

  /**
   * Sets the tick label offset
   * 
   * @param newTickLabelOffset the new tick label offset
   */
  public void setTickLabelOffset(float newTickLabelOffset) {
    tickLabelOffset = newTickLabelOffset;
  }

  /**
   * Sets if the axis label should be drawn or not
   * 
   * @param newDrawAxisLabel true if the axis label should be drawn
   */
  public void setDrawAxisLabel(boolean newDrawAxisLabel) {
    drawAxisLabel = newDrawAxisLabel;
  }

  /**
   * Sets the axis label text
   * 
   * @param text the new axis label text
   */
  public void setAxisLabelText(String text) {
    lab.setText(text);
  }

  /**
   * Sets the font name
   * 
   * @param newFontName the name of the new font
   */
  public void setFontName(String newFontName) {
    fontName = newFontName;
    font = parent.createFont(fontName, fontSize);
  }

  /**
   * Sets the font color
   * 
   * @param newFontColor the new font color
   */
  public void setFontColor(int newFontColor) {
    fontColor = newFontColor;
  }

  /**
   * Sets the font size
   * 
   * @param newFontSize the new font size
   */
  public void setFontSize(int newFontSize) {
    if (newFontSize > 0) {
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }

  /**
   * Sets all the font properties at once
   * 
   * @param newFontName the name of the new font
   * @param newFontColor the new font color
   * @param newFontSize the new font size
   */
  public void setFontProperties(String newFontName, int newFontColor, int newFontSize) {
    if (newFontSize > 0) {
      fontName = newFontName;
      fontColor = newFontColor;
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }

  /**
   * Sets the font properties in the axis and the axis label
   * 
   * @param newFontName the new font name
   * @param newFontColor the new font color
   * @param newFontSize the new font size
   */
  public void setAllFontProperties(String newFontName, int newFontColor, int newFontSize) {
    setFontProperties(newFontName, newFontColor, newFontSize);
    lab.setFontProperties(newFontName, newFontColor, newFontSize);
  }

  /**
   * Returns a copy of the axis ticks
   * 
   * @return a copy of the axis ticks
   */
  public float[] getTicks() {
    if (fixedTicks) {
      float[] a = new float[ticks.size()];

      for (int i = 0; i < ticks.size(); i++) {
        a[i] = ticks.get(i);
      }

      return a;
    } else {
      return removeOutsideTicks();
    }
  }

  /**
   * Returns the axis ticks
   * 
   * @return the axis ticks
   */
  public ArrayList<Float> getTicksRef() {
    return ticks;
  }

  /**
   * Returns a copy of the axis ticks positions in the plot reference system
   * 
   * @return a copy of the axis ticks positions in the plot reference system
   */
  public float[] getPlotTicks() {
    if (fixedTicks) {
      float[] a = new float[plotTicks.size()];

      for (int i = 0; i < plotTicks.size(); i++) {
        a[i] = plotTicks.get(i);
      }

      return a;
    } else {
      return removeOutsidePlotTicks();
    }
  }

  /**
   * Returns the axis ticks positions in the plot reference system
   * 
   * @return the axis ticks positions in the plot reference system
   */
  public ArrayList<Float> getPlotTicksRef() {
    return plotTicks;
  }

  /**
   * Returns the axis label
   * 
   * @return the axis label
   */
  public GAxisLabel getAxisLabel() {
    return lab;
  }
}

/**
 * ##library.name##
 * ##library.sentence##
 * ##library.url##
 *
 * Copyright ##copyright## ##author##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 * 
 * @author      ##author##
 * @modified    ##date##
 * @version     ##library.prettyVersion## (##library.version##)
 */

//package grafica;

import processing.core.PApplet;
import processing.core.PConstants;
import processing.core.PFont;

/**
 * Axis label class.
 * 
 * @author ##author##
 */
public class GAxisLabel implements PConstants {
  // The parent Processing applet
  protected final PApplet parent;

  // General properties
  protected final int type;
  protected float[] dim;
  protected float relativePos;
  protected float plotPos;
  protected float offset;
  protected boolean rotate;

  // Text properties
  protected String text;
  protected int textAlignment;
  protected String fontName;
  protected int fontColor;
  protected int fontSize;
  protected PFont font;

  /**
   * Constructor
   * 
   * @param parent the parent Processing applet
   * @param type the axis label type. It can be X, Y, TOP or RIGHT
   * @param dim the plot box dimensions in pixels
   */
  public GAxisLabel(PApplet parent, int type, float[] dim) {
    this.parent = parent;

    this.type = (type == X || type == Y || type == TOP || type == RIGHT) ? type : X;
    this.dim = dim.clone();
    relativePos = 0.5f;
    plotPos = (this.type == X || this.type == TOP) ? relativePos * this.dim[0] : -relativePos * this.dim[1];
    offset = 35;
    rotate = (this.type == X || this.type == TOP) ? false : true;

    text = "";
    textAlignment = CENTER;
    fontName = "SansSerif.plain";
    fontColor = color(0);
    fontSize = 13;
    font = this.parent.createFont(fontName, fontSize);
  }

  /**
   * Draws the axis label
   */
  public void draw() {
    switch (type) {
    case X:
      drawAsXLabel();
      break;
    case Y:
      drawAsYLabel();
      break;
    case TOP:
      drawAsTopLabel();
      break;
    case RIGHT:
      drawAsRightLabel();
      break;
    }
  }

  /**
   * Draws the axis label as an X axis label
   */
  protected void drawAsXLabel() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.noStroke();

    if (rotate) {
      parent.textAlign(RIGHT, CENTER);

      parent.pushMatrix();
      parent.translate(plotPos, offset);
      parent.rotate(-HALF_PI);
      parent.text(text, 0, 0);
      parent.popMatrix();
    } else {
      parent.textAlign(textAlignment, TOP);
      parent.text(text, plotPos, offset);
    }

    parent.popStyle();
  }

  /**
   * Draws the axis label as a Y axis label
   */
  protected void drawAsYLabel() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.noStroke();

    if (rotate) {
      parent.textAlign(textAlignment, BOTTOM);

      parent.pushMatrix();
      parent.translate(-offset, plotPos);
      parent.rotate(-HALF_PI);
      parent.text(text, 0, 0);
      parent.popMatrix();
    } else {
      parent.textAlign(RIGHT, CENTER);
      parent.text(text, -offset, plotPos);
    }

    parent.popStyle();
  }

  /**
   * Draws the axis label as a TOP axis label
   */
  protected void drawAsTopLabel() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.noStroke();

    if (rotate) {
      parent.textAlign(LEFT, CENTER);

      parent.pushMatrix();
      parent.translate(plotPos, -offset - dim[1]);
      parent.rotate(-HALF_PI);
      parent.text(text, 0, 0);
      parent.popMatrix();
    } else {
      parent.textAlign(textAlignment, BOTTOM);
      parent.text(text, plotPos, -offset - dim[1]);
    }

    parent.popStyle();
  }

  /**
   * Draws the axis label as a RIGHT axis label
   */
  protected void drawAsRightLabel() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.noStroke();

    if (rotate) {
      parent.textAlign(textAlignment, TOP);

      parent.pushMatrix();
      parent.translate(offset + dim[0], plotPos);
      parent.rotate(-HALF_PI);
      parent.text(text, 0, 0);
      parent.popMatrix();
    } else {
      parent.textAlign(LEFT, CENTER);
      parent.text(text, offset + dim[0], plotPos);
    }

    parent.popStyle();
  }

  /**
   * Sets the plot box dimensions information
   * 
   * @param xDim the new plot box x dimension
   * @param yDim the new plot box y dimension
   */
  public void setDim(float xDim, float yDim) {
    if (xDim > 0 && yDim > 0) {
      dim[0] = xDim;
      dim[1] = yDim;
      plotPos = (type == X || type == TOP) ? relativePos * dim[0] : -relativePos * dim[1];
    }
  }

  /**
   * Sets the plot box dimensions information
   * 
   * @param newDim the new plot box dimensions information
   */
  public void setDim(float[] newDim) {
    setDim(newDim[0], newDim[1]);
  }

  /**
   * Sets the label relative position in the axis
   * 
   * @param newRelativePos the new relative position in the axis
   */
  public void setRelativePos(float newRelativePos) {
    relativePos = newRelativePos;
    plotPos = (type == X || type == TOP) ? relativePos * dim[0] : -relativePos * dim[1];
  }

  /**
   * Sets the axis label offset
   * 
   * @param newOffset the new axis label offset
   */
  public void setOffset(float newOffset) {
    offset = newOffset;
  }

  /**
   * Sets if the axis label should be rotated or not
   * 
   * @param newRotate true if the axis label should be rotated
   */
  public void setRotate(boolean newRotate) {
    rotate = newRotate;
  }

  /**
   * Sets the axis label text
   * 
   * @param newText the new axis label text
   */
  public void setText(String newText) {
    text = newText;
  }

  /**
   * Sets the axis label type of text alignment
   * 
   * @param newTextAlignment the new type of text alignment
   */
  public void setTextAlignment(int newTextAlignment) {
    if (newTextAlignment == CENTER || newTextAlignment == LEFT || newTextAlignment == RIGHT) {
      textAlignment = newTextAlignment;
    }
  }

  /**
   * Sets the font name
   * 
   * @param newFontName the name of the new font
   */
  public void setFontName(String newFontName) {
    fontName = newFontName;
    font = parent.createFont(fontName, fontSize);
  }

  /**
   * Sets the font color
   * 
   * @param newFontColor the new font color
   */
  public void setFontColor(int newFontColor) {
    fontColor = newFontColor;
  }

  /**
   * Sets the font size
   * 
   * @param newFontSize the new font size
   */
  public void setFontSize(int newFontSize) {
    if (newFontSize > 0) {
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }

  /**
   * Sets all the font properties at once
   * 
   * @param newFontName the name of the new font
   * @param newFontColor the new font color
   * @param newFontSize the new font size
   */
  public void setFontProperties(String newFontName, int newFontColor, int newFontSize) {
    if (newFontSize > 0) {
      fontName = newFontName;
      fontColor = newFontColor;
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }
}

/**
 * ##library.name##
 * ##library.sentence##
 * ##library.url##
 *
 * Copyright ##copyright## ##author##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 * 
 * @author      ##author##
 * @modified    ##date##
 * @version     ##library.prettyVersion## (##library.version##)
 */

//package grafica;

import java.util.ArrayList;
import processing.core.PApplet;
import processing.core.PConstants;
import processing.core.PFont;

/**
 * Histogram class.
 * 
 * @author ##author##
 */
public class GHistogram implements PConstants {
  // The parent Processing applet
  protected final PApplet parent;

  // General properties
  protected int type;
  protected float[] dim;
  protected GPointsArray plotPoints;
  protected boolean visible;
  protected float[] separations;
  protected int[] bgColors;
  protected int[] lineColors;
  protected float[] lineWidths;
  protected ArrayList<Float> differences;
  protected ArrayList<Float> leftSides;
  protected ArrayList<Float> rightSides;

  // Labels properties
  protected float labelsOffset;
  protected boolean drawLabels;
  protected boolean rotateLabels;
  protected String fontName;
  protected int fontColor;
  protected int fontSize;
  protected PFont font;

  /**
   * Constructor
   * 
   * @param parent the parent Processing applet
   * @param type the histogram type. It can be GPlot.VERTICAL or GPlot.HORIZONTAL
   * @param dim the plot box dimensions in pixels
   * @param plotPoints the points positions in the plot reference system
   */
  public GHistogram(PApplet parent, int type, float[] dim, GPointsArray plotPoints) {
    this.parent = parent;

    this.type = (type == GPlot.VERTICAL || type == GPlot.HORIZONTAL) ? type : GPlot.VERTICAL;
    this.dim = dim.clone();
    this.plotPoints = new GPointsArray(plotPoints);
    visible = true;
    separations = new float[] { 2 };
    bgColors = new int[] { color(150, 150, 255) };
    lineColors = new int[] { color(100, 100, 255) };
    lineWidths = new float[] { 1 };

    int nPoints = plotPoints.getNPoints();
    differences = new ArrayList<Float>(nPoints);
    leftSides = new ArrayList<Float>(nPoints);
    rightSides = new ArrayList<Float>(nPoints);
    initializeArrays(nPoints);
    updateArrays();

    labelsOffset = 8;
    drawLabels = false;
    rotateLabels = false;
    fontName = "SansSerif.plain";
    fontColor = color(0);
    fontSize = 11;
    font = this.parent.createFont(fontName, fontSize);
  }

  /**
   * Fills the differences, leftSides and rightSides arrays
   */
  protected void initializeArrays(int nPoints) {
    if (differences.size() < nPoints) {
      for (int i = differences.size(); i < nPoints; i++) {
        differences.add(0f);
        leftSides.add(0f);
        rightSides.add(0f);
      }
    } else {
      differences.subList(nPoints, differences.size()).clear();
    }
  }

  /**
   * Updates the differences, leftSides and rightSides arrays
   */
  protected void updateArrays() {
    int nPoints = plotPoints.getNPoints();

    if (nPoints == 1) {
      leftSides.set(0, (type == GPlot.VERTICAL) ? 0.2f * dim[0] : 0.2f * dim[1]);
      rightSides.set(0, leftSides.get(0));
    } else if (nPoints > 1) {
      // Calculate the differences between consecutive points
      for (int i = 0; i < nPoints - 1; i++) {
        if (plotPoints.isValid(i) && plotPoints.isValid(i + 1)) {
          float separation = separations[i % separations.length];
          float diff;

          if (type == GPlot.VERTICAL) {
            diff = plotPoints.getX(i + 1) - plotPoints.getX(i);
          } else {
            diff = plotPoints.getY(i + 1) - plotPoints.getY(i);
          }

          if (diff > 0) {
            differences.set(i, (diff - separation) / 2f);
          } else {
            differences.set(i, (diff + separation) / 2f);
          }
        } else {
          differences.set(i, 0f);
        }
      }

      // Fill the leftSides and rightSides arrays
      leftSides.set(0, differences.get(0));
      rightSides.set(0, differences.get(0));

      for (int i = 1; i < nPoints - 1; i++) {
        leftSides.set(i, differences.get(i - 1));
        rightSides.set(i, differences.get(i));
      }

      leftSides.set(nPoints - 1, differences.get(nPoints - 2));
      rightSides.set(nPoints - 1, differences.get(nPoints - 2));
    }
  }

  /**
   * Draws the histogram
   * 
   * @param plotBasePoint the histogram base point in the plot reference system
   */
  public void draw(GPoint plotBasePoint) {
    if (visible) {
      // Calculate the baseline for the histogram
      float baseline = 0;

      if (plotBasePoint.isValid()) {
        baseline = (type == GPlot.VERTICAL) ? plotBasePoint.getY() : plotBasePoint.getX();
      }

      // Draw the rectangles
      parent.pushStyle();
      parent.rectMode(CORNERS);
      parent.strokeCap(SQUARE);

      for (int i = 0; i < plotPoints.getNPoints(); i++) {
        if (plotPoints.isValid(i)) {
          // Obtain the corners
          float x1, x2, y1, y2;

          if (type == GPlot.VERTICAL) {
            x1 = plotPoints.getX(i) - leftSides.get(i);
            x2 = plotPoints.getX(i) + rightSides.get(i);
            y1 = plotPoints.getY(i);
            y2 = baseline;
          } else {
            x1 = baseline;
            x2 = plotPoints.getX(i);
            y1 = plotPoints.getY(i) - leftSides.get(i);
            y2 = plotPoints.getY(i) + rightSides.get(i);
          }

          if (x1 < 0) {
            x1 = 0;
          } else if (x1 > dim[0]) {
            x1 = dim[0];
          }

          if (-y1 < 0) {
            y1 = 0;
          } else if (-y1 > dim[1]) {
            y1 = -dim[1];
          }

          if (x2 < 0) {
            x2 = 0;
          } else if (x2 > dim[0]) {
            x2 = dim[0];
          }

          if (-y2 < 0) {
            y2 = 0;
          } else if (-y2 > dim[1]) {
            y2 = -dim[1];
          }

          // Draw the rectangle
          float lw = lineWidths[i % lineWidths.length];
          parent.fill(bgColors[i % bgColors.length]);
          parent.stroke(lineColors[i % lineColors.length]);
          parent.strokeWeight(lw);

          if (Math.abs(x2 - x1) > 2 * lw && Math.abs(y2 - y1) > 2 * lw) {
            parent.rect(x1, y1, x2, y2);
          } else if ((type == GPlot.VERTICAL && x2 != x1 && !(y1 == y2 && (y1 == 0 || y1 == -dim[1])))
              || (type == GPlot.HORIZONTAL && y2 != y1 && !(x1 == x2 && (x1 == 0 || x1 == dim[0])))) {
            parent.rect(x1, y1, x2, y2);
            parent.line(x1, y1, x1, y2);
            parent.line(x2, y1, x2, y2);
            parent.line(x1, y1, x2, y1);
            parent.line(x1, y2, x2, y2);
          }
        }
      }

      parent.popStyle();

      // Draw the labels
      if (drawLabels) {
        drawHistLabels();
      }
    }
  }

  /**
   * Draws the histogram labels
   */
  protected void drawHistLabels() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.noStroke();

    if (type == GPlot.VERTICAL) {
      if (rotateLabels) {
        parent.textAlign(RIGHT, CENTER);

        for (int i = 0; i < plotPoints.getNPoints(); i++) {
          if (plotPoints.isValid(i) && plotPoints.getX(i) >= 0 && plotPoints.getX(i) <= dim[0]) {
            parent.pushMatrix();
            parent.translate(plotPoints.getX(i), labelsOffset);
            parent.rotate(-HALF_PI);
            parent.text(plotPoints.getLabel(i), 0, 0);
            parent.popMatrix();
          }
        }
      } else {
        parent.textAlign(CENTER, TOP);

        for (int i = 0; i < plotPoints.getNPoints(); i++) {
          if (plotPoints.isValid(i) && plotPoints.getX(i) >= 0 && plotPoints.getX(i) <= dim[0]) {
            parent.text(plotPoints.getLabel(i), plotPoints.getX(i), labelsOffset);
          }
        }
      }
    } else {
      if (rotateLabels) {
        parent.textAlign(CENTER, BOTTOM);

        for (int i = 0; i < plotPoints.getNPoints(); i++) {
          if (plotPoints.isValid(i) && -plotPoints.getY(i) >= 0 && -plotPoints.getY(i) <= dim[1]) {
            parent.pushMatrix();
            parent.translate(-labelsOffset, plotPoints.getY(i));
            parent.rotate(-HALF_PI);
            parent.text(plotPoints.getLabel(i), 0, 0);
            parent.popMatrix();
          }
        }
      } else {
        parent.textAlign(RIGHT, CENTER);

        for (int i = 0; i < plotPoints.getNPoints(); i++) {
          if (plotPoints.isValid(i) && -plotPoints.getY(i) >= 0 && -plotPoints.getY(i) <= dim[1]) {
            parent.text(plotPoints.getLabel(i), -labelsOffset, plotPoints.getY(i));
          }
        }
      }
    }

    parent.popStyle();
  }

  /**
   * Sets the type of histogram to display
   * 
   * @param newType the new type of histogram to display
   */
  public void setType(int newType) {
    if (newType != type && (newType == GPlot.VERTICAL || newType == GPlot.HORIZONTAL)) {
      type = newType;
      updateArrays();
    }
  }

  /**
   * Sets the plot box dimensions information
   * 
   * @param xDim the new plot box x dimension
   * @param yDim the new plot box y dimension
   */
  public void setDim(float xDim, float yDim) {
    if (xDim > 0 && yDim > 0) {
      dim[0] = xDim;
      dim[1] = yDim;
      updateArrays();
    }
  }

  /**
   * Sets the plot box dimensions information
   * 
   * @param newDim the new plot box dimensions information
   */
  public void setDim(float[] newDim) {
    setDim(newDim[0], newDim[1]);
  }

  /**
   * Sets the histogram plot points
   * 
   * @param newPlotPoints the new point positions in the plot reference system
   */
  public void setPlotPoints(GPointsArray newPlotPoints) {
    plotPoints.set(newPlotPoints);
    initializeArrays(plotPoints.getNPoints());
    updateArrays();
  }

  /**
   * Sets one of the histogram plot points
   * 
   * @param index the point position
   * @param newPlotPoint the new point positions in the plot reference system
   */
  public void setPlotPoint(int index, GPoint newPlotPoint) {
    plotPoints.set(index, newPlotPoint);
    updateArrays();
  }

  /**
   * Adds a new plot point to the histogram
   * 
   * @param newPlotPoint the new point position in the plot reference system
   */
  public void addPlotPoint(GPoint newPlotPoint) {
    plotPoints.add(newPlotPoint);
    initializeArrays(plotPoints.getNPoints());
    updateArrays();
  }

  /**
   * Adds a new plot point to the histogram
   * 
   * @param index the position to add the point
   * @param newPlotPoint the new point position in the plot reference system
   */
  public void addPlotPoint(int index, GPoint newPlotPoint) {
    plotPoints.add(index, newPlotPoint);
    initializeArrays(plotPoints.getNPoints());
    updateArrays();
  }

  /**
   * Adds a new plot points to the histogram
   * 
   * @param newPlotPoints the new points positions in the plot reference system
   */
  public void addPlotPoints(GPointsArray newPlotPoints) {
    plotPoints.add(newPlotPoints);
    initializeArrays(plotPoints.getNPoints());
    updateArrays();
  }

  /**
   * Removes one of the points from the histogram
   * 
   * @param index the point position
   */
  public void removePlotPoint(int index) {
    plotPoints.remove(index);
    initializeArrays(plotPoints.getNPoints());
    updateArrays();
  }

  /**
   * Sets the separations between the histogram elements
   * 
   * @param newSeparations the new separations between the histogram elements
   */
  public void setSeparations(float[] newSeparations) {
    separations = newSeparations.clone();
    updateArrays();
  }

  /**
   * Sets the background colors of the histogram elements
   * 
   * @param newBgColors the new background colors of the histogram elements
   */
  public void setBgColors(int[] newBgColors) {
    bgColors = newBgColors.clone();
  }

  /**
   * Sets the line colors of the histogram elements
   * 
   * @param newLineColors the new line colors of the histogram elements
   */
  public void setLineColors(int[] newLineColors) {
    lineColors = newLineColors.clone();
  }

  /**
   * Sets the line widths of the histogram elements
   * 
   * @param newLineWidths the new line widths of the histogram elements
   */
  public void setLineWidths(float[] newLineWidths) {
    lineWidths = newLineWidths.clone();
  }

  /**
   * Sets if the histogram should be visible or not
   * 
   * @param newVisible true if the histogram should be visible
   */
  public void setVisible(boolean newVisible) {
    visible = newVisible;
  }

  /**
   * Sets the histogram labels offset
   * 
   * @param newLabelsOffset the new histogram labels offset
   */
  public void setLabelsOffset(float newLabelsOffset) {
    labelsOffset = newLabelsOffset;
  }

  /**
   * Sets if the histogram labels should be drawn or not
   * 
   * @param newDrawLabels true if the histogram labels should be drawn
   */
  public void setDrawLabels(boolean newDrawLabels) {
    drawLabels = newDrawLabels;
  }

  /**
   * Sets if the histogram labels should be rotated or not
   * 
   * @param newRotateLabels true if the histogram labels should be rotated
   */
  public void setRotateLabels(boolean newRotateLabels) {
    rotateLabels = newRotateLabels;
  }

  /**
   * Sets the font name
   * 
   * @param newFontName the name of the new font
   */
  public void setFontName(String newFontName) {
    fontName = newFontName;
    font = parent.createFont(fontName, fontSize);
  }

  /**
   * Sets the font color
   * 
   * @param newFontColor the new font color
   */
  public void setFontColor(int newFontColor) {
    fontColor = newFontColor;
  }

  /**
   * Sets the font size
   * 
   * @param newFontSize the new font size
   */
  public void setFontSize(int newFontSize) {
    if (newFontSize > 0) {
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }

  /**
   * Sets all the font properties at once
   * 
   * @param newFontName the name of the new font
   * @param newFontColor the new font color
   * @param newFontSize the new font size
   */
  public void setFontProperties(String newFontName, int newFontColor, int newFontSize) {
    if (newFontSize > 0) {
      fontName = newFontName;
      fontColor = newFontColor;
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }
}

/**
 * ##library.name##
 * ##library.sentence##
 * ##library.url##
 *
 * Copyright ##copyright## ##author##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 * 
 * @author      ##author##
 * @modified    ##date##
 * @version     ##library.prettyVersion## (##library.version##)
 */

//package grafica;

import java.util.ArrayList;
import processing.core.PApplet;
import processing.core.PConstants;
import processing.core.PFont;
import processing.core.PImage;
import processing.core.PShape;

/**
 * Layer class. A GLayer usually contains an array of points and a histogram
 * 
 * @author ##author##
 */
public class GLayer implements PConstants {
  // The parent Processing applet
  protected final PApplet parent;

  // General properties
  protected final String id;
  protected float[] dim;
  protected float[] xLim;
  protected float[] yLim;
  protected boolean xLog;
  protected boolean yLog;

  // Points properties
  protected GPointsArray points;
  protected GPointsArray plotPoints;
  protected ArrayList<Boolean> inside;
  protected int[] pointColors;
  protected float[] pointSizes;

  // Line properties
  protected int lineColor;
  protected float lineWidth;

  // Histogram properties
  protected GHistogram hist;
  protected GPoint histBasePoint;

  // Labels properties
  protected int labelBgColor;
  protected float[] labelSeparation;
  protected String fontName;
  protected int fontColor;
  protected int fontSize;
  protected PFont font;

  // Helper variable
  protected float[][] cuts = new float[4][2];

  /**
   * GLayer constructor
   * 
   * @param parent the parent Processing applet
   * @param id the layer id
   * @param dim the plot box dimensions in pixels
   * @param xLim the horizontal limits
   * @param yLim the vertical limits
   * @param xLog the horizontal scale. True if it's logarithmic
   * @param yLog the vertical scale. True if it's logarithmic
   */
  public GLayer(PApplet parent, String id, float[] dim, float[] xLim, float[] yLim, boolean xLog, boolean yLog) {
    this.parent = parent;

    this.id = id;
    this.dim = dim.clone();
    this.xLim = xLim.clone();
    this.yLim = yLim.clone();
    this.xLog = xLog;
    this.yLog = yLog;

    // Do some sanity checks
    if (this.xLog && (this.xLim[0] <= 0 || this.xLim[1] <= 0)) {
      PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      PApplet.println("Will set horizontal limits to (0.1, 10)");
      this.xLim[0] = 0.1f;
      this.xLim[1] = 10;
    }

    if (this.yLog && (this.yLim[0] <= 0 || this.yLim[1] <= 0)) {
      PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      PApplet.println("Will set vertical limits to (0.1, 10)");
      this.yLim[0] = 0.1f;
      this.yLim[1] = 10;
    }

    // Continue with the rest
    points = new GPointsArray();
    plotPoints = new GPointsArray();
    inside = new ArrayList<Boolean>();
    pointColors = new int[] { color(255, 0, 0, 150) };
    pointSizes = new float[] { 7 };

    lineColor = color(0, 150);
    lineWidth = 1;

    hist = null;
    histBasePoint = new GPoint(0, 0);

    labelBgColor = color(255, 200);
    labelSeparation = new float[] { 7, 7 };
    fontName = "SansSerif.plain";
    fontColor = color(0);
    fontSize = 11;
    font = this.parent.createFont(fontName, fontSize);
  }

  /**
   * Checks if the provided number is a valid number (i.e. is not NaN and is not Infinite)
   * 
   * @param number the number to check
   * 
   * @return true if it's not NaN and is not Infinite
   */
  protected boolean isValidNumber(float number) {
    return !Float.isNaN(number) && !Float.isInfinite(number);
  }

  /**
   * Checks if the layer's id is equal to a given id
   * 
   * @param someId the id to check
   * 
   * @return true if the provided id is equal to the layer's id
   */
  public boolean isId(String someId) {
    return id.equals(someId);
  }

  /**
   * Calculates the position of the x value in the plot reference system
   * 
   * @param x the x value
   * 
   * @return the x position in the plot reference system
   */
  public float valueToXPlot(float x) {
    if (xLog) {
      return dim[0] * PApplet.log(x / xLim[0]) / PApplet.log(xLim[1] / xLim[0]);
    } else {
      return dim[0] * (x - xLim[0]) / (xLim[1] - xLim[0]);
    }
  }

  /**
   * Calculates the position of the y value in the plot reference system
   * 
   * @param y the y value
   * 
   * @return the y position in the plot reference system
   */
  public float valueToYPlot(float y) {
    if (yLog) {
      return -dim[1] * PApplet.log(y / yLim[0]) / PApplet.log(yLim[1] / yLim[0]);
    } else {
      return -dim[1] * (y - yLim[0]) / (yLim[1] - yLim[0]);
    }
  }

  /**
   * Calculates the position of a given (x, y) point in the plot reference system
   * 
   * @param x the x value
   * @param y the y value
   * 
   * @return the (x, y) position in the plot reference system
   */
  public float[] valueToPlot(float x, float y) {
    return new float[] { valueToXPlot(x), valueToYPlot(y) };
  }

  /**
   * Calculates the position of a given point in the plot reference system
   * 
   * @param point the point
   * 
   * @return a copy of the point with its position transformed to the plot reference system
   */
  public GPoint valueToPlot(GPoint point) {
    return new GPoint(valueToXPlot(point.getX()), valueToYPlot(point.getY()), point.getLabel());
  }

  /**
   * Calculates the positions of a given set of points in the plot reference system
   * 
   * @param pts the set of points
   * 
   * @return a copy of the set of point with their positions transformed to the plot reference system
   */
  public GPointsArray valueToPlot(GPointsArray pts) {
    int nPoints = pts.getNPoints();
    GPointsArray plotPts = new GPointsArray(nPoints);

    // Go case by case. More code, but it's faster
    if (xLog && yLog) {
      float xScalingFactor = dim[0] / PApplet.log(xLim[1] / xLim[0]);
      float yScalingFactor = -dim[1] / PApplet.log(yLim[1] / yLim[0]);

      for (int i = 0; i < nPoints; i++) {
        float xPlot = PApplet.log(pts.getX(i) / xLim[0]) * xScalingFactor;
        float yPlot = PApplet.log(pts.getY(i) / yLim[0]) * yScalingFactor;
        plotPts.add(xPlot, yPlot, pts.getLabel(i));
      }
    } else if (xLog) {
      float xScalingFactor = dim[0] / PApplet.log(xLim[1] / xLim[0]);
      float yScalingFactor = -dim[1] / (yLim[1] - yLim[0]);

      for (int i = 0; i < nPoints; i++) {
        float xPlot = PApplet.log(pts.getX(i) / xLim[0]) * xScalingFactor;
        float yPlot = (pts.getY(i) - yLim[0]) * yScalingFactor;
        plotPts.add(xPlot, yPlot, pts.getLabel(i));
      }
    } else if (yLog) {
      float xScalingFactor = dim[0] / (xLim[1] - xLim[0]);
      float yScalingFactor = -dim[1] / PApplet.log(yLim[1] / yLim[0]);

      for (int i = 0; i < nPoints; i++) {
        float xPlot = (pts.getX(i) - xLim[0]) * xScalingFactor;
        float yPlot = PApplet.log(pts.getY(i) / yLim[0]) * yScalingFactor;
        plotPts.add(xPlot, yPlot, pts.getLabel(i));
      }
    } else {
      float xScalingFactor = dim[0] / (xLim[1] - xLim[0]);
      float yScalingFactor = -dim[1] / (yLim[1] - yLim[0]);

      for (int i = 0; i < nPoints; i++) {
        float xPlot = (pts.getX(i) - xLim[0]) * xScalingFactor;
        float yPlot = (pts.getY(i) - yLim[0]) * yScalingFactor;
        plotPts.add(xPlot, yPlot, pts.getLabel(i));
      }
    }

    return plotPts;
  }

  /**
   * Updates the position of the layer points to the plot reference system
   */
  protected void updatePlotPoints() {
    int nPoints = points.getNPoints();

    // Go case by case. More code, but it should be faster
    if (xLog && yLog) {
      float xScalingFactor = dim[0] / PApplet.log(xLim[1] / xLim[0]);
      float yScalingFactor = -dim[1] / PApplet.log(yLim[1] / yLim[0]);

      for (int i = 0; i < nPoints; i++) {
        float xPlot = PApplet.log(points.getX(i) / xLim[0]) * xScalingFactor;
        float yPlot = PApplet.log(points.getY(i) / yLim[0]) * yScalingFactor;
        plotPoints.set(i, xPlot, yPlot, points.getLabel(i));
      }
    } else if (xLog) {
      float xScalingFactor = dim[0] / PApplet.log(xLim[1] / xLim[0]);
      float yScalingFactor = -dim[1] / (yLim[1] - yLim[0]);

      for (int i = 0; i < nPoints; i++) {
        float xPlot = PApplet.log(points.getX(i) / xLim[0]) * xScalingFactor;
        float yPlot = (points.getY(i) - yLim[0]) * yScalingFactor;
        plotPoints.set(i, xPlot, yPlot, points.getLabel(i));
      }
    } else if (yLog) {
      float xScalingFactor = dim[0] / (xLim[1] - xLim[0]);
      float yScalingFactor = -dim[1] / PApplet.log(yLim[1] / yLim[0]);

      for (int i = 0; i < nPoints; i++) {
        float xPlot = (points.getX(i) - xLim[0]) * xScalingFactor;
        float yPlot = PApplet.log(points.getY(i) / yLim[0]) * yScalingFactor;
        plotPoints.set(i, xPlot, yPlot, points.getLabel(i));
      }
    } else {
      float xScalingFactor = dim[0] / (xLim[1] - xLim[0]);
      float yScalingFactor = -dim[1] / (yLim[1] - yLim[0]);

      for (int i = 0; i < nPoints; i++) {
        float xPlot = (points.getX(i) - xLim[0]) * xScalingFactor;
        float yPlot = (points.getY(i) - yLim[0]) * yScalingFactor;
        plotPoints.set(i, xPlot, yPlot, points.getLabel(i));
      }
    }

    // Remove the unused points
    if (plotPoints.getNPoints() > nPoints) {
      plotPoints.setNPoints(nPoints);
    }
  }

  /**
   * Returns the plot x value at a given position in the plot reference system
   * 
   * @param xPlot x position in the plot reference system
   * 
   * @return the x values at the xPlot position
   */
  protected float xPlotToValue(float xPlot) {
    if (xLog) {
      return PApplet.exp(PApplet.log(xLim[0]) + PApplet.log(xLim[1] / xLim[0]) * xPlot / dim[0]);
    } else {
      return xLim[0] + (xLim[1] - xLim[0]) * xPlot / dim[0];
    }
  }

  /**
   * Returns the plot y value at a given position in the plot reference system
   * 
   * @param yPlot y position in the plot reference system
   * 
   * @return the y values at the yPlot position
   */
  protected float yPlotToValue(float yPlot) {
    if (yLog) {
      return PApplet.exp(PApplet.log(yLim[0]) - PApplet.log(yLim[1] / yLim[0]) * yPlot / dim[1]);
    } else {
      return yLim[0] - (yLim[1] - yLim[0]) * yPlot / dim[1];
    }
  }

  /**
   * Returns the plot values at a given position in the plot reference system
   * 
   * @param xPlot x position in the plot reference system
   * @param yPlot y position in the plot reference system
   * 
   * @return the (x, y) values at the (xPlot, yPlot) position
   */
  public float[] plotToValue(float xPlot, float yPlot) {
    return new float[] { xPlotToValue(xPlot), yPlotToValue(yPlot) };
  }

  /**
   * Checks if a given (xPlot, yPlot) position in the plot reference system is inside the layer limits
   * 
   * @param xPlot x position in the plot reference system
   * @param yPlot y position in the plot reference system
   * 
   * @return true if the (xPlot, yPlot) position is inside the layer limits
   */
  public boolean isInside(float xPlot, float yPlot) {
    return (xPlot >= 0) && (xPlot <= dim[0]) && (-yPlot >= 0) && (-yPlot <= dim[1]);
  }

  /**
   * Checks if a given point in the plot reference system is inside the layer limits
   * 
   * @param plotPoint the point in the plot reference system
   * 
   * @return true if the point is inside the layer limits
   */
  public boolean isInside(GPoint plotPoint) {
    return (plotPoint.isValid()) ? isInside(plotPoint.getX(), plotPoint.getY()) : false;
  }

  /**
   * Checks if a given set of points in the plot reference system is inside the layer limits
   * 
   * @param plotPts the set of points to check
   * 
   * @return a boolean array with the elements set to true if the point is inside the layer limits
   */
  public boolean[] isInside(GPointsArray plotPts) {
    boolean[] pointsInside = new boolean[plotPts.getNPoints()];

    for (int i = 0; i < pointsInside.length; i++) {
      pointsInside[i] = isInside(plotPts.get(i));
    }

    return pointsInside;
  }

  /**
   * Updates the array list that tells if the points are inside the layer limits or not
   */
  protected void updateInsideList() {
    // Clear the list first, because the size could have changed
    inside.clear();

    // Refill the list
    int nPoints = plotPoints.getNPoints();

    for (int i = 0; i < nPoints; i++) {
      inside.add(isInside(plotPoints.get(i)));
    }
  }

  /**
   * Returns the position index of the closest point (if any) to a given position in the plot reference system
   * 
   * @param xPlot x position in the plot reference system
   * @param yPlot y position in the plot reference system
   * 
   * @return the position index of closest point to the specified position. Returns -1 if there is no close point.
   */
  public int getPointIndexAtPlotPos(float xPlot, float yPlot) {
    int pointIndex = -1;

    if (isInside(xPlot, yPlot)) {
      int nPoints = plotPoints.getNPoints();
      float minDistSq = Float.MAX_VALUE;
      int nSizes = pointSizes.length;

      for (int i = 0; i < nPoints; i++) {
        if (inside.get(i)) {
          float distSq = PApplet.sq(plotPoints.getX(i) - xPlot) + PApplet.sq(plotPoints.getY(i) - yPlot);

          if (distSq < PApplet.max(PApplet.sq(pointSizes[i % nSizes] / 2.0f), 25)) {
            if (distSq < minDistSq) {
              minDistSq = distSq;
              pointIndex = i;
            }
          }
        }
      }
    }

    return pointIndex;
  }

  /**
   * Returns the closest point (if any) to a given position in the plot reference system
   * 
   * @param xPlot x position in the plot reference system
   * @param yPlot y position in the plot reference system
   * 
   * @return the closest point to the specified position. Returns null if there is no close point.
   */
  public GPoint getPointAtPlotPos(float xPlot, float yPlot) {
    int pointIndex = getPointIndexAtPlotPos(xPlot, yPlot);

    return (pointIndex >= 0) ? points.get(pointIndex) : null;
  }

  /**
   * Obtains the box intersections of the line that connects two given points
   * 
   * @param plotPoint1 the first point in the plot reference system
   * @param plotPoint2 the second point in the plot reference system
   * 
   * @return the number of box intersections in the plot reference system
   */
  protected int obtainBoxIntersections(GPoint plotPoint1, GPoint plotPoint2) {
    int nCuts = 0;

    if (plotPoint1.isValid() && plotPoint2.isValid()) {
      float x1 = plotPoint1.getX();
      float y1 = plotPoint1.getY();
      float x2 = plotPoint2.getX();
      float y2 = plotPoint2.getY();
      boolean inside1 = isInside(x1, y1);
      boolean inside2 = isInside(x2, y2);

      // Check if the line between the two points could cut the box
      // borders
      boolean dontCut = (inside1 && inside2) || (x1 < 0 && x2 < 0) || (x1 > dim[0] && x2 > dim[0])
        || (-y1 < 0 && -y2 < 0) || (-y1 > dim[1] && -y2 > dim[1]);

      if (!dontCut) {
        // Obtain the axis cuts of the line that cross the two points
        float deltaX = x2 - x1;
        float deltaY = y2 - y1;

        if (deltaX == 0) {
          nCuts = 2;
          cuts[0][0] = x1;
          cuts[0][1] = 0;
          cuts[1][0] = x1;
          cuts[1][1] = -dim[1];
        } else if (deltaY == 0) {
          nCuts = 2;
          cuts[0][0] = 0;
          cuts[0][1] = y1;
          cuts[1][0] = dim[0];
          cuts[1][1] = y1;
        } else {
          // Obtain the straight line (y = yCut + slope*x) that
          // crosses the two points
          float slope = deltaY / deltaX;
          float yCut = y1 - slope * x1;

          // Calculate the axis cuts of that line
          nCuts = 4;
          cuts[0][0] = -yCut / slope;
          cuts[0][1] = 0;
          cuts[1][0] = (-dim[1] - yCut) / slope;
          cuts[1][1] = -dim[1];
          cuts[2][0] = 0;
          cuts[2][1] = yCut;
          cuts[3][0] = dim[0];
          cuts[3][1] = yCut + slope * dim[0];
        }

        // Select only the cuts that fall inside the box and are located
        // between the two points
        nCuts = getValidCuts(cuts, nCuts, plotPoint1, plotPoint2);

        // Make sure we have the correct number of cuts
        if (inside1 || inside2) {
          // One of the points is inside. We should have one cut only
          if (nCuts != 1) {
            GPoint pointInside = (inside1) ? plotPoint1 : plotPoint2;

            // If too many cuts
            if (nCuts > 1) {
              nCuts = removeDuplicatedCuts(cuts, nCuts, 0);

              if (nCuts > 1) {
                nCuts = removePointFromCuts(cuts, nCuts, pointInside, 0);

                // In case of rounding number errors
                if (nCuts > 1) {
                  nCuts = removeDuplicatedCuts(cuts, nCuts, 0.001f);

                  if (nCuts > 1) {
                    nCuts = removePointFromCuts(cuts, nCuts, pointInside, 0.001f);
                  }
                }
              }
            }

            // If the cut is missing, then it must be equal to the
            // point inside
            if (nCuts == 0) {
              nCuts = 1;
              cuts[0][0] = pointInside.getX();
              cuts[0][1] = pointInside.getY();
            }
          }
        } else {
          // Both points are outside. We should have either two cuts
          // or none
          if (nCuts > 2) {
            nCuts = removeDuplicatedCuts(cuts, nCuts, 0);

            // In case of rounding number errors
            if (nCuts > 2) {
              nCuts = removeDuplicatedCuts(cuts, nCuts, 0.001f);
            }
          }

          // If we have two cuts, order them (the closest to the first
          // point goes first)
          if (nCuts == 2) {
            if ((PApplet.sq(cuts[0][0] - x1) + PApplet.sq(cuts[0][1] - y1)) > (PApplet.sq(cuts[1][0] - x1)
              + PApplet.sq(cuts[1][1] - y1))) {
              cuts[2][0] = cuts[0][0];
              cuts[2][1] = cuts[0][1];
              cuts[0][0] = cuts[1][0];
              cuts[0][1] = cuts[1][1];
              cuts[1][0] = cuts[2][0];
              cuts[1][1] = cuts[2][1];
            }
          }

          // If one cut is missing, add the same one twice
          if (nCuts == 1) {
            nCuts = 2;
            cuts[1][0] = cuts[0][0];
            cuts[1][1] = cuts[0][1];
          }
        }

        // Some sanity checks
        if ((inside1 || inside2) && nCuts != 1) {
          PApplet.println("There should be one cut!!!");
        } else if (!inside1 && !inside2 && nCuts != 0 && nCuts != 2) {
          PApplet.println("There should be either 0 or 2 cuts!!! " + nCuts + " were found");
        }
      }
    }

    return nCuts;
  }

  /**
   * Returns only those cuts that are inside the box region and lie between the two given points
   * 
   * @param cuts the axis cuts
   * @param nCuts the number of cuts
   * @param plotPoint1 the first point in the plot reference system
   * @param plotPoint2 the second point in the plot reference system
   * 
   * @return the number of cuts inside the box region and between the two points
   */
  protected int getValidCuts(float[][] cuts, int nCuts, GPoint plotPoint1, GPoint plotPoint2) {
    float x1 = plotPoint1.getX();
    float y1 = plotPoint1.getY();
    float x2 = plotPoint2.getX();
    float y2 = plotPoint2.getY();
    float deltaX = Math.abs(x2 - x1);
    float deltaY = Math.abs(y2 - y1);
    int counter = 0;

    for (int i = 0; i < nCuts; i++) {
      // Check that the cut is inside the inner plotting area
      if (isInside(cuts[i][0], cuts[i][1])) {
        // Check that the cut falls between the two points
        if (Math.abs(cuts[i][0] - x1) <= deltaX && Math.abs(cuts[i][1] - y1) <= deltaY
          && Math.abs(cuts[i][0] - x2) <= deltaX && Math.abs(cuts[i][1] - y2) <= deltaY) {
          cuts[counter][0] = cuts[i][0];
          cuts[counter][1] = cuts[i][1];
          counter++;
        }
      }
    }

    return counter;
  }

  /**
   * Removes duplicated cuts
   * 
   * @param cuts the box cuts
   * @param nCuts the number of cuts
   * @param tolerance maximum distance after which the points can't be duplicates
   * 
   * @return the number of cuts without the duplications
   */
  protected int removeDuplicatedCuts(float[][] cuts, int nCuts, float tolerance) {
    int counter = 0;

    for (int i = 0; i < nCuts; i++) {
      boolean repeated = false;

      for (int j = 0; j < counter; j++) {
        if (Math.abs(cuts[j][0] - cuts[i][0]) <= tolerance && Math.abs(cuts[j][1] - cuts[i][1]) <= tolerance) {
          repeated = true;
          break;
        }
      }

      if (!repeated) {
        cuts[counter][0] = cuts[i][0];
        cuts[counter][1] = cuts[i][1];
        counter++;
      }
    }

    return counter;
  }

  /**
   * Removes cuts that are equal to a given point
   * 
   * @param cuts the box cuts
   * @param nCuts the number of cuts
   * @param plotPoint the point to compare with
   * @param tolerance maximum distance after which the points can't be equal
   * 
   * @return the number of cuts without the point duplications
   */
  protected int removePointFromCuts(float[][] cuts, int nCuts, GPoint plotPoint, float tolerance) {
    float x = plotPoint.getX();
    float y = plotPoint.getY();
    int counter = 0;

    for (int i = 0; i < nCuts; i++) {
      if (Math.abs(cuts[i][0] - x) > tolerance || Math.abs(cuts[i][1] - y) > tolerance) {
        cuts[counter][0] = cuts[i][0];
        cuts[counter][1] = cuts[i][1];
        counter++;
      }
    }

    return counter;
  }

  /**
   * Initializes the histogram
   * 
   * @param histType the type of histogram to use. It can be GPlot.VERTICAL or GPlot.HORIZONTAL
   */
  public void startHistogram(int histType) {
    hist = new GHistogram(parent, histType, dim, plotPoints);
  }

  /**
   * Checks if two points overlap (Hegyesi 2021.01.19.)
   * 
   * @param p1 the first point
   * 
   * @param p1 the second point
   * 
   * @param p1Size the size of the first point
   * 
   * @param p2Size the size of the  second point
   * 
   * @return true if the points overlap
   */
  private boolean overlap(GPoint p1, GPoint p2, float p1Size, float p2Size) {
    float distSq = PApplet.sq(p1.getX() - p2.getX()) + PApplet.sq(p1.getY() - p2.getY());
    return distSq < PApplet.sq( (p1Size + p2Size) / 2 );
  }

  /**
   * Draws the points inside the layer limits (Hegyesi mod. 2021.01.19.)
   */
  public void drawPoints() {
    int nPoints = plotPoints.getNPoints();
    if (nPoints == 0) return;

    int nColors = pointColors.length;
    int nSizes = pointSizes.length;
    GPoint lastDrawnPoint = plotPoints.get(0);
    float lastDrawnPointSize = pointSizes[0];

    parent.pushStyle();
    parent.ellipseMode(CENTER);
    parent.noStroke();

    if (nColors == 1 && nSizes == 1) {
      parent.fill(pointColors[0]);

      for (int i = 0; i < nPoints; i++) {
        if (inside.get(i)) {
          if ( i == 0 || !overlap(lastDrawnPoint, plotPoints.get(i), pointSizes[0], pointSizes[0]) ) {
            parent.ellipse(plotPoints.getX(i), plotPoints.getY(i), pointSizes[0], pointSizes[0]);
            lastDrawnPoint = plotPoints.get(i);
          }
        }
      }
    } else if (nColors == 1) {
      parent.fill(pointColors[0]);

      for (int i = 0; i < nPoints; i++) {
        if (inside.get(i)) {
          if ( i == 0 || !overlap(lastDrawnPoint, plotPoints.get(i), lastDrawnPointSize, pointSizes[i % nSizes]) ) {
            parent.ellipse(plotPoints.getX(i), plotPoints.getY(i), pointSizes[i % nSizes], 
              pointSizes[i % nSizes]);
            lastDrawnPoint = plotPoints.get(i);
            lastDrawnPointSize = pointSizes[i % nSizes];
          }
        }
      }
    } else if (nSizes == 1) {
      for (int i = 0; i < nPoints; i++) {
        if (inside.get(i)) {
          if ( i == 0 || !overlap(lastDrawnPoint, plotPoints.get(i), pointSizes[0], pointSizes[0]) ) {
            parent.fill(pointColors[i % nColors]);
            parent.ellipse(plotPoints.getX(i), plotPoints.getY(i), pointSizes[0], pointSizes[0]);
            lastDrawnPoint = plotPoints.get(i);
          }
        }
      }
    } else {
      for (int i = 0; i < nPoints; i++) {
        if (inside.get(i)) {
          if ( i == 0 || !overlap(lastDrawnPoint, plotPoints.get(i), lastDrawnPointSize, pointSizes[i % nSizes]) ) {
            parent.fill(pointColors[i % nColors]);
            parent.ellipse(plotPoints.getX(i), plotPoints.getY(i), pointSizes[i % nSizes], 
              pointSizes[i % nSizes]);
            lastDrawnPoint = plotPoints.get(i);
            lastDrawnPointSize = pointSizes[i % nSizes];
          }
        }
      }
    }

    parent.popStyle();
  }

  /**
   * Draws the points inside the layer limits
   * 
   * @param pointShape the shape that should be used to represent the points
   */
  public void drawPoints(PShape pointShape) {
    int nPoints = plotPoints.getNPoints();
    int nColors = pointColors.length;

    parent.pushStyle();
    parent.shapeMode(CENTER);

    if (nColors == 1) {
      parent.fill(pointColors[0]);
      parent.stroke(pointColors[0]);

      for (int i = 0; i < nPoints; i++) {
        if (inside.get(i)) {
          parent.shape(pointShape, plotPoints.getX(i), plotPoints.getY(i));
        }
      }
    } else {
      for (int i = 0; i < nPoints; i++) {
        if (inside.get(i)) {
          parent.fill(pointColors[i % nColors]);
          parent.stroke(pointColors[i % nColors]);
          parent.shape(pointShape, plotPoints.getX(i), plotPoints.getY(i));
        }
      }
    }

    parent.popStyle();
  }

  /**
   * Draws the points inside the layer limits
   * 
   * @param pointImg the image that should be used to represent the points
   */
  public void drawPoints(PImage pointImg) {
    int nPoints = plotPoints.getNPoints();

    parent.pushStyle();
    parent.imageMode(CENTER);

    for (int i = 0; i < nPoints; i++) {
      if (inside.get(i)) {
        parent.image(pointImg, plotPoints.getX(i), plotPoints.getY(i));
      }
    }

    parent.popStyle();
  }

  /**
   * Draws a point
   * 
   * @param point the point to draw
   * @param pointColor color to use
   * @param pointSize point size in pixels
   */
  public void drawPoint(GPoint point, int pointColor, float pointSize) {
    float xPlot = valueToXPlot(point.getX());
    float yPlot = valueToYPlot(point.getY());

    if (isInside(xPlot, yPlot)) {
      parent.pushStyle();
      parent.ellipseMode(CENTER);
      parent.fill(pointColor);
      parent.noStroke();
      parent.ellipse(xPlot, yPlot, pointSize, pointSize);
      parent.popStyle();
    }
  }

  /**
   * Draws a point
   * 
   * @param point the point to draw
   */
  public void drawPoint(GPoint point) {
    drawPoint(point, pointColors[0], pointSizes[0]);
  }

  /**
   * Draws a point
   * 
   * @param point the point to draw
   * @param pointShape the shape that should be used to represent the point
   */
  public void drawPoint(GPoint point, PShape pointShape) {
    float xPlot = valueToXPlot(point.getX());
    float yPlot = valueToYPlot(point.getY());

    parent.pushStyle();
    parent.shapeMode(CENTER);

    if (isInside(xPlot, yPlot)) {
      parent.shape(pointShape, xPlot, yPlot);
    }

    parent.popStyle();
  }

  /**
   * Draws a point
   * 
   * @param point the point to draw
   * @param pointShape the shape that should be used to represent the points
   * @param pointColor color to use
   */
  public void drawPoint(GPoint point, PShape pointShape, int pointColor) {
    float xPlot = valueToXPlot(point.getX());
    float yPlot = valueToYPlot(point.getY());

    if (isInside(xPlot, yPlot)) {
      parent.pushStyle();
      parent.shapeMode(CENTER);
      parent.fill(pointColor);
      parent.stroke(pointColor);
      parent.strokeCap(SQUARE);
      parent.shape(pointShape, xPlot, yPlot);
      parent.popStyle();
    }
  }

  /**
   * Draws a point
   * 
   * @param point the point to draw
   * @param pointImg the image that should be used to represent the point
   */
  public void drawPoint(GPoint point, PImage pointImg) {
    float xPlot = valueToXPlot(point.getX());
    float yPlot = valueToYPlot(point.getY());

    parent.pushStyle();
    parent.imageMode(CENTER);

    if (isInside(xPlot, yPlot)) {
      parent.image(pointImg, xPlot, yPlot);
    }

    parent.popStyle();
  }

  /**
   * Draws lines connecting consecutive points in the layer
   */
  public void drawLines() {
    parent.pushStyle();
    parent.noFill();
    parent.stroke(lineColor);
    parent.strokeWeight(lineWidth);
    parent.strokeCap(SQUARE);

    for (int i = 0; i < plotPoints.getNPoints() - 1; i++) {
      if (inside.get(i) && inside.get(i + 1)) {
        parent.line(plotPoints.getX(i), plotPoints.getY(i), plotPoints.getX(i + 1), plotPoints.getY(i + 1));
      } else if (plotPoints.isValid(i) && plotPoints.isValid(i + 1)) {
        // At least one of the points is outside the inner region.
        // Obtain the valid line box intersections
        int nCuts = obtainBoxIntersections(plotPoints.get(i), plotPoints.get(i + 1));

        if (inside.get(i)) {
          parent.line(plotPoints.getX(i), plotPoints.getY(i), cuts[0][0], cuts[0][1]);
        } else if (inside.get(i + 1)) {
          parent.line(cuts[0][0], cuts[0][1], plotPoints.getX(i + 1), plotPoints.getY(i + 1));
        } else if (nCuts >= 2) {
          parent.line(cuts[0][0], cuts[0][1], cuts[1][0], cuts[1][1]);
        }
      }
    }

    parent.popStyle();
  }

  /**
   * Draws a line between two points
   * 
   * @param point1 first point
   * @param point2 second point
   * @param lc line color
   * @param lw line width
   */
  public void drawLine(GPoint point1, GPoint point2, int lc, float lw) {
    GPoint plotPoint1 = valueToPlot(point1);
    GPoint plotPoint2 = valueToPlot(point2);

    if (plotPoint1.isValid() && plotPoint2.isValid()) {
      boolean inside1 = isInside(plotPoint1);
      boolean inside2 = isInside(plotPoint2);

      parent.pushStyle();
      parent.noFill();
      parent.stroke(lc);
      parent.strokeWeight(lw);
      parent.strokeCap(SQUARE);

      if (inside1 && inside2) {
        parent.line(plotPoint1.getX(), plotPoint1.getY(), plotPoint2.getX(), plotPoint2.getY());
      } else {
        // At least one of the points is outside the inner region.
        // Obtain the valid line box intersections
        int nCuts = obtainBoxIntersections(plotPoint1, plotPoint2);

        if (inside1) {
          parent.line(plotPoint1.getX(), plotPoint1.getY(), cuts[0][0], cuts[0][1]);
        } else if (inside2) {
          parent.line(cuts[0][0], cuts[0][1], plotPoint2.getX(), plotPoint2.getY());
        } else if (nCuts >= 2) {
          parent.line(cuts[0][0], cuts[0][1], cuts[1][0], cuts[1][1]);
        }
      }

      parent.popStyle();
    }
  }

  /**
   * Draws a line between two points
   * 
   * @param point1 first point
   * @param point2 second point
   */
  public void drawLine(GPoint point1, GPoint point2) {
    drawLine(point1, point2, lineColor, lineWidth);
  }

  /**
   * Draws a line defined by the slope and the cut in the y axis
   * 
   * @param slope the line slope
   * @param yCut the line y axis cut
   * @param lc line color
   * @param lw line width
   */
  public void drawLine(float slope, float yCut, int lc, float lw) {
    GPoint point1, point2;

    if (xLog && yLog) {
      point1 = new GPoint(xLim[0], PApplet.pow(10, slope * PApplet.log(xLim[0]) / GPlot.LOG10 + yCut));
      point2 = new GPoint(xLim[1], PApplet.pow(10, slope * PApplet.log(xLim[1]) / GPlot.LOG10 + yCut));
    } else if (xLog) {
      point1 = new GPoint(xLim[0], slope * PApplet.log(xLim[0]) / GPlot.LOG10 + yCut);
      point2 = new GPoint(xLim[1], slope * PApplet.log(xLim[1]) / GPlot.LOG10 + yCut);
    } else if (yLog) {
      point1 = new GPoint(xLim[0], PApplet.pow(10, slope * xLim[0] + yCut));
      point2 = new GPoint(xLim[1], PApplet.pow(10, slope * xLim[1] + yCut));
    } else {
      point1 = new GPoint(xLim[0], slope * xLim[0] + yCut);
      point2 = new GPoint(xLim[1], slope * xLim[1] + yCut);
    }

    drawLine(point1, point2, lc, lw);
  }

  /**
   * Draws a line defined by the slope and the cut in the y axis
   * 
   * @param slope the line slope
   * @param yCut the line y axis cut
   */
  public void drawLine(float slope, float yCut) {
    drawLine(slope, yCut, lineColor, lineWidth);
  }

  /**
   * Draws an horizontal line
   * 
   * @param value line horizontal value
   * @param lc line color
   * @param lw line width
   */
  public void drawHorizontalLine(float value, int lc, float lw) {
    float yPlot = valueToYPlot(value);

    if (isValidNumber(yPlot) && -yPlot >= 0 && -yPlot <= dim[1]) {
      parent.pushStyle();
      parent.noFill();
      parent.stroke(lc);
      parent.strokeWeight(lw);
      parent.strokeCap(SQUARE);
      parent.line(0, yPlot, dim[0], yPlot);
      parent.popStyle();
    }
  }

  /**
   * Draws an horizontal line
   * 
   * @param value line horizontal value
   */
  public void drawHorizontalLine(float value) {
    drawHorizontalLine(value, lineColor, lineWidth);
  }

  /**
   * Draws a vertical line
   * 
   * @param value line vertical value
   * @param lc line color
   * @param lw line width
   */
  public void drawVerticalLine(float value, int lc, float lw) {
    float xPlot = valueToXPlot(value);

    if (isValidNumber(xPlot) && xPlot >= 0 && xPlot <= dim[0]) {
      parent.pushStyle();
      parent.noFill();
      parent.stroke(lc);
      parent.strokeWeight(lw);
      parent.strokeCap(SQUARE);
      parent.line(xPlot, 0, xPlot, -dim[1]);
      parent.popStyle();
    }
  }

  /**
   * Draws a vertical line
   * 
   * @param value line vertical value
   */
  public void drawVerticalLine(float value) {
    drawVerticalLine(value, lineColor, lineWidth);
  }

  /**
   * Draws a filled contour connecting consecutive points in the layer and a reference value
   * 
   * @param contourType the type of contours to use. It can be GPlot.VERTICAL or GPlot.HORIZONTAL
   * @param referenceValue the reference value to use to close the contour
   */
  public void drawFilledContour(int contourType, float referenceValue) {
    // Get the points that compose the shape
    GPointsArray shapePoints = null;

    if (contourType == GPlot.HORIZONTAL) {
      shapePoints = getHorizontalShape(referenceValue);
    } else if (contourType == GPlot.VERTICAL) {
      shapePoints = getVerticalShape(referenceValue);
    }

    // Draw the shape
    if (shapePoints != null && shapePoints.getNPoints() > 0) {
      parent.pushStyle();
      parent.fill(lineColor);
      parent.noStroke();

      parent.beginShape();

      for (int i = 0; i < shapePoints.getNPoints(); i++) {
        if (shapePoints.isValid(i)) {
          parent.vertex(shapePoints.getX(i), shapePoints.getY(i));
        }
      }

      parent.endShape(CLOSE);

      parent.popStyle();
    }
  }

  /**
   * Obtains the shape points of the horizontal contour that connects consecutive layer points and a reference value
   * 
   * @param referenceValue the reference value to use to close the contour
   * 
   * @return the shape points
   */
  protected GPointsArray getHorizontalShape(float referenceValue) {
    // Collect the points and cuts inside the box
    int nPoints = plotPoints.getNPoints();
    GPointsArray shapePoints = new GPointsArray(2 * nPoints);
    int indexFirstPoint = -1;
    int indexLastPoint = -1;

    for (int i = 0; i < nPoints; i++) {
      if (plotPoints.isValid(i)) {
        boolean addedPoints = false;

        // Add the point if it's inside the box
        if (inside.get(i)) {
          shapePoints.add(plotPoints.getX(i), plotPoints.getY(i), "normal point");
          addedPoints = true;
        } else if (plotPoints.getX(i) >= 0 && plotPoints.getX(i) <= dim[0]) {
          // If it's outside, add the projection of the point on the
          // horizontal axes
          if (-plotPoints.getY(i) < 0) {
            shapePoints.add(plotPoints.getX(i), 0, "projection");
            addedPoints = true;
          } else {
            shapePoints.add(plotPoints.getX(i), -dim[1], "projection");
            addedPoints = true;
          }
        }

        // Add the box cuts if there is any
        int nextIndex = i + 1;

        while (nextIndex < nPoints - 1 && !plotPoints.isValid(nextIndex)) {
          nextIndex++;
        }

        if (nextIndex < nPoints && plotPoints.isValid(nextIndex)) {
          int nCuts = obtainBoxIntersections(plotPoints.get(i), plotPoints.get(nextIndex));

          for (int j = 0; j < nCuts; j++) {
            shapePoints.add(cuts[j][0], cuts[j][1], "cut");
            addedPoints = true;
          }
        }

        if (addedPoints) {
          if (indexFirstPoint < 0) {
            indexFirstPoint = i;
          }

          indexLastPoint = i;
        }
      }
    }

    // Continue if there are points in the shape
    if (shapePoints.getNPoints() > 0) {
      // Calculate the starting point
      GPoint startPoint = new GPoint(shapePoints.get(0));

      if (startPoint.getX() != 0 && startPoint.getX() != dim[0]) {
        if (startPoint.getLabel().equals("cut")) {
          if (plotPoints.getX(indexFirstPoint) < 0) {
            startPoint.setX(0);
            startPoint.setLabel("extreme");
          } else {
            startPoint.setX(dim[0]);
            startPoint.setLabel("extreme");
          }
        } else if (indexFirstPoint != 0) {
          // Get the previous valid point
          int prevIndex = indexFirstPoint - 1;

          while (prevIndex > 0 && !plotPoints.isValid(prevIndex)) {
            prevIndex--;
          }

          if (plotPoints.isValid(prevIndex)) {
            if (plotPoints.getX(prevIndex) < 0) {
              startPoint.setX(0);
              startPoint.setLabel("extreme");
            } else {
              startPoint.setX(dim[0]);
              startPoint.setLabel("extreme");
            }
          }
        }
      }

      // Calculate the end point
      GPoint endPoint = new GPoint(shapePoints.getLastPoint());

      if (endPoint.getX() != 0 && endPoint.getX() != dim[0] && indexLastPoint != nPoints - 1) {
        int nextIndex = indexLastPoint + 1;

        while (nextIndex < nPoints - 1 && !plotPoints.isValid(nextIndex)) {
          nextIndex++;
        }

        if (plotPoints.isValid(nextIndex)) {
          if (plotPoints.getX(nextIndex) < 0) {
            endPoint.setX(0);
            endPoint.setLabel("extreme");
          } else {
            endPoint.setX(dim[0]);
            endPoint.setLabel("extreme");
          }
        }
      }

      // Add the end point if it's a new extreme
      if (endPoint.getLabel().equals("extreme")) {
        shapePoints.add(endPoint);
      }

      // Add the reference connections
      if (yLog && referenceValue <= 0) {
        referenceValue = Math.min(yLim[0], yLim[1]);
      }

      float[] plotReference = valueToPlot(1, referenceValue);

      if (-plotReference[1] < 0) {
        shapePoints.add(endPoint.getX(), 0);
        shapePoints.add(startPoint.getX(), 0);
      } else if (-plotReference[1] > dim[1]) {
        shapePoints.add(endPoint.getX(), -dim[1]);
        shapePoints.add(startPoint.getX(), -dim[1]);
      } else {
        shapePoints.add(endPoint.getX(), plotReference[1]);
        shapePoints.add(startPoint.getX(), plotReference[1]);
      }

      // Add the starting point if it's a new extreme
      if (startPoint.getLabel().equals("extreme")) {
        shapePoints.add(startPoint);
      }
    }

    return shapePoints;
  }

  /**
   * Obtains the shape points of the vertical contour that connects consecutive layer points and a reference value
   * 
   * @param referenceValue the reference value to use to close the contour
   * 
   * @return the shape points
   */
  protected GPointsArray getVerticalShape(float referenceValue) {
    // Collect the points and cuts inside the box
    int nPoints = plotPoints.getNPoints();
    GPointsArray shapePoints = new GPointsArray(2 * nPoints);
    int indexFirstPoint = -1;
    int indexLastPoint = -1;

    for (int i = 0; i < nPoints; i++) {
      if (plotPoints.isValid(i)) {
        boolean addedPoints = false;

        // Add the point if it's inside the box
        if (inside.get(i)) {
          shapePoints.add(plotPoints.getX(i), plotPoints.getY(i), "normal point");
          addedPoints = true;
        } else if (-plotPoints.getY(i) >= 0 && -plotPoints.getY(i) <= dim[1]) {
          // If it's outside, add the projection of the point on the
          // vertical axes
          if (plotPoints.getX(i) < 0) {
            shapePoints.add(0, plotPoints.getY(i), "projection");
            addedPoints = true;
          } else {
            shapePoints.add(dim[0], plotPoints.getY(i), "projection");
            addedPoints = true;
          }
        }

        // Add the box cuts if there is any
        int nextIndex = i + 1;

        while (nextIndex < nPoints - 1 && !plotPoints.isValid(nextIndex)) {
          nextIndex++;
        }

        if (nextIndex < nPoints && plotPoints.isValid(nextIndex)) {
          int nCuts = obtainBoxIntersections(plotPoints.get(i), plotPoints.get(nextIndex));

          for (int j = 0; j < nCuts; j++) {
            shapePoints.add(cuts[j][0], cuts[j][1], "cut");
            addedPoints = true;
          }
        }

        if (addedPoints) {
          if (indexFirstPoint < 0) {
            indexFirstPoint = i;
          }

          indexLastPoint = i;
        }
      }
    }

    // Continue if there are points in the shape
    if (shapePoints.getNPoints() > 0) {
      // Calculate the starting point
      GPoint startPoint = new GPoint(shapePoints.get(0));

      if (startPoint.getY() != 0 && startPoint.getY() != -dim[1]) {
        if (startPoint.getLabel().equals("cut")) {
          if (-plotPoints.getY(indexFirstPoint) < 0) {
            startPoint.setY(0);
            startPoint.setLabel("extreme");
          } else {
            startPoint.setY(-dim[1]);
            startPoint.setLabel("extreme");
          }
        } else if (indexFirstPoint != 0) {
          // Get the previous valid point
          int prevIndex = indexFirstPoint - 1;

          while (prevIndex > 0 && !plotPoints.isValid(prevIndex)) {
            prevIndex--;
          }

          if (plotPoints.isValid(prevIndex)) {
            if (-plotPoints.getY(prevIndex) < 0) {
              startPoint.setY(0);
              startPoint.setLabel("extreme");
            } else {
              startPoint.setY(-dim[1]);
              startPoint.setLabel("extreme");
            }
          }
        }
      }

      // Calculate the end point
      GPoint endPoint = new GPoint(shapePoints.getLastPoint());

      if (endPoint.getY() != 0 && endPoint.getY() != -dim[1] && indexLastPoint != nPoints - 1) {
        int nextIndex = indexLastPoint + 1;

        while (nextIndex < nPoints - 1 && !plotPoints.isValid(nextIndex)) {
          nextIndex++;
        }

        if (plotPoints.isValid(nextIndex)) {
          if (-plotPoints.getY(nextIndex) < 0) {
            endPoint.setY(0);
            endPoint.setLabel("extreme");
          } else {
            endPoint.setY(-dim[1]);
            endPoint.setLabel("extreme");
          }
        }
      }

      // Add the end point if it's a new extreme
      if (endPoint.getLabel().equals("extreme")) {
        shapePoints.add(endPoint);
      }

      // Add the reference connections
      if (xLog && referenceValue <= 0) {
        referenceValue = Math.min(xLim[0], xLim[1]);
      }

      float[] plotReference = valueToPlot(referenceValue, 1);

      if (plotReference[0] < 0) {
        shapePoints.add(0, endPoint.getY());
        shapePoints.add(0, startPoint.getY());
      } else if (plotReference[0] > dim[0]) {
        shapePoints.add(dim[0], endPoint.getY());
        shapePoints.add(dim[0], startPoint.getY());
      } else {
        shapePoints.add(plotReference[0], endPoint.getY());
        shapePoints.add(plotReference[0], startPoint.getY());
      }

      // Add the starting point if it's a new extreme
      if (startPoint.getLabel().equals("extreme")) {
        shapePoints.add(startPoint);
      }
    }

    return shapePoints;
  }

  /**
   * Draws the label of a given point
   * 
   * @param point the point
   */
  public void drawLabel(GPoint point) {
    float xPlot = valueToXPlot(point.getX());
    float yPlot = valueToYPlot(point.getY());

    if (isValidNumber(xPlot) && isValidNumber(yPlot)) {
      float xLabelPos = xPlot + labelSeparation[0];
      float yLabelPos = yPlot - labelSeparation[1];
      float delta = fontSize / 4;

      parent.pushStyle();
      parent.rectMode(CORNER);
      parent.noStroke();
      parent.textFont(font);
      parent.textSize(fontSize);
      parent.textAlign(LEFT, BOTTOM);

      // Draw the background
      parent.fill(labelBgColor);
      parent.rect(xLabelPos - delta, yLabelPos - fontSize - delta, parent.textWidth(point.getLabel()) + 2 * delta, 
        fontSize + 2 * delta);

      // Draw the text
      parent.fill(fontColor);
      parent.text(point.getLabel(), xLabelPos, yLabelPos);
      parent.popStyle();
    }
  }

  /**
   * Draws the label of the closest point in the layer to a given plot position
   * 
   * @param xPlot x position in the plot reference system
   * @param yPlot y position in the plot reference system
   */
  public void drawLabelAtPlotPos(float xPlot, float yPlot) {
    GPoint point = getPointAtPlotPos(xPlot, yPlot);

    if (point != null) {
      drawLabel(point);
    }
  }

  /**
   * Draws the histogram
   */
  public void drawHistogram() {
    if (hist != null) {
      hist.draw(valueToPlot(histBasePoint));
    }
  }

  /**
   * Draws a polygon defined by a set of points
   * 
   * @param polygonPoints the points that define the polygon
   * @param polygonColor the color to use to draw the polygon (contour and background)
   */
  public void drawPolygon(GPointsArray polygonPoints, int polygonColor) {
    if (polygonPoints.getNPoints() > 2) {
      // Remove the polygon invalid points
      GPointsArray plotPolygonPoints = valueToPlot(polygonPoints);
      plotPolygonPoints.removeInvalidPoints();

      // Create a temporal array with the points inside the plotting area
      // and the valid box cuts
      int nPoints = plotPolygonPoints.getNPoints();
      GPointsArray tmp = new GPointsArray(2 * nPoints);

      for (int i = 0; i < nPoints; i++) {
        if (isInside(plotPolygonPoints.get(i))) {
          tmp.add(plotPolygonPoints.getX(i), plotPolygonPoints.getY(i), "normal point");
        }

        // Obtain the cuts with the next point
        int nextIndex = (i + 1 < nPoints) ? i + 1 : 0;
        int nCuts = obtainBoxIntersections(plotPolygonPoints.get(i), plotPolygonPoints.get(nextIndex));

        if (nCuts == 1) {
          tmp.add(cuts[0][0], cuts[0][1], "single cut");
        } else if (nCuts > 1) {
          tmp.add(cuts[0][0], cuts[0][1], "double cut");
          tmp.add(cuts[1][0], cuts[1][1], "double cut");
        }
      }

      // Final version of the polygon
      nPoints = tmp.getNPoints();
      GPointsArray croppedPoly = new GPointsArray(2 * nPoints);

      for (int i = 0; i < nPoints; i++) {
        // Add the point
        croppedPoly.add(tmp.get(i));

        // Add new points in case we have two consecutive cuts, one of
        // them is single, and they are in consecutive axes
        int next = (i + 1 < nPoints) ? i + 1 : 0;
        String label = tmp.getLabel(i);
        String nextLabel = tmp.getLabel(next);

        boolean cond = (label.equals("single cut") && nextLabel.equals("single cut"))
          || (label.equals("single cut") && nextLabel.equals("double cut"))
          || (label.equals("double cut") && nextLabel.equals("single cut"));

        if (cond) {
          float x1 = tmp.getX(i);
          float y1 = tmp.getY(i);
          float x2 = tmp.getX(next);
          float y2 = tmp.getY(next);
          float deltaX = Math.abs(x2 - x1);
          float deltaY = Math.abs(y2 - y1);

          // Check that they come from consecutive axes
          if (deltaX > 0 && deltaY > 0 && deltaX != dim[0] && deltaY != dim[1]) {
            float x = (x1 == 0 || x1 == dim[0]) ? x1 : x2;
            float y = (y1 == 0 || y1 == -dim[1]) ? y1 : y2;
            croppedPoly.add(x, y, "special cut");
          }
        }
      }

      // Draw the cropped polygon
      if (croppedPoly.getNPoints() > 2) {
        parent.pushStyle();
        parent.fill(polygonColor);
        parent.noStroke();

        parent.beginShape();

        for (int i = 0; i < croppedPoly.getNPoints(); i++) {
          parent.vertex(croppedPoly.getX(i), croppedPoly.getY(i));
        }

        parent.endShape(CLOSE);

        parent.popStyle();
      }
    }
  }

  /**
   * Draws an annotation at a given plot value
   * 
   * @param text the annotation text
   * @param x x plot value
   * @param y y plot value
   * @param horAlign text horizontal alignment. It can be RIGHT, LEFT or CENTER
   * @param verAlign text vertical alignment. It can be TOP, BOTTOM or CENTER
   */
  public void drawAnnotation(String text, float x, float y, int horAlign, int verAlign) {
    float xPlot = valueToXPlot(x);
    float yPlot = valueToYPlot(y);

    if (isValidNumber(xPlot) && isValidNumber(yPlot) && isInside(xPlot, yPlot)) {
      if (horAlign != CENTER && horAlign != RIGHT && horAlign != LEFT) {
        horAlign = LEFT;
      }

      if (verAlign != CENTER && verAlign != TOP && verAlign != BOTTOM) {
        verAlign = CENTER;
      }

      parent.pushStyle();
      parent.textFont(font);
      parent.textSize(fontSize);
      parent.fill(fontColor);
      parent.textAlign(horAlign, verAlign);
      parent.text(text, xPlot, yPlot);
      parent.popStyle();
    }
  }

  /**
   * Sets the layer dimensions
   * 
   * @param xDim the new layer x dimension
   * @param yDim the new layer y dimension
   */
  public void setDim(float xDim, float yDim) {
    if (xDim > 0 && yDim > 0) {
      dim[0] = xDim;
      dim[1] = yDim;
      updatePlotPoints();

      if (hist != null) {
        hist.setDim(xDim, yDim);
        hist.setPlotPoints(plotPoints);
      }
    }
  }

  /**
   * Sets the layer dimensions, which should be equal to the plot box dimensions
   * 
   * @param newDim the new layer dimensions
   */
  public void setDim(float[] newDim) {
    setDim(newDim[0], newDim[1]);
  }

  /**
   * Sets the horizontal limits
   * 
   * @param xMin the minimum limit value
   * @param xMax the maximum limit value
   */
  public void setXLim(float xMin, float xMax) {
    if (xMin != xMax && isValidNumber(xMin) && isValidNumber(xMax)) {
      // Make sure the new limits makes sense
      if (xLog && (xMin <= 0 || xMax <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        xLim[0] = xMin;
        xLim[1] = xMax;
        updatePlotPoints();
        updateInsideList();

        if (hist != null) {
          hist.setPlotPoints(plotPoints);
        }
      }
    }
  }

  /**
   * Sets the horizontal limits
   * 
   * @param newXLim the new horizontal limits
   */
  public void setXLim(float[] newXLim) {
    setXLim(newXLim[0], newXLim[1]);
  }

  /**
   * Sets the vertical limits
   * 
   * @param yMin the minimum limit value
   * @param yMax the maximum limit value
   */
  public void setYLim(float yMin, float yMax) {
    if (yMin != yMax && isValidNumber(yMin) && isValidNumber(yMax)) {
      // Make sure the new limits makes sense
      if (yLog && (yMin <= 0 || yMax <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        yLim[0] = yMin;
        yLim[1] = yMax;
        updatePlotPoints();
        updateInsideList();

        if (hist != null) {
          hist.setPlotPoints(plotPoints);
        }
      }
    }
  }

  /**
   * Sets the vertical limits
   * 
   * @param newYLim the new vertical limits
   */
  public void setYLim(float[] newYLim) {
    setYLim(newYLim[0], newYLim[1]);
  }

  /**
   * Sets the horizontal and vertical limits
   * 
   * @param xMin the minimum horizontal limit value
   * @param xMax the maximum horizontal limit value
   * @param yMin the minimum vertical limit value
   * @param yMax the maximum vertical limit value
   */
  public void setXYLim(float xMin, float xMax, float yMin, float yMax) {
    if (xMin != xMax && yMin != yMax && isValidNumber(xMin) && isValidNumber(xMax) && isValidNumber(yMin)
      && isValidNumber(yMax)) {
      // Make sure the new limits make sense
      if (xLog && (xMin <= 0 || xMax <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        xLim[0] = xMin;
        xLim[1] = xMax;
      }

      if (yLog && (yMin <= 0 || yMax <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        yLim[0] = yMin;
        yLim[1] = yMax;
      }

      updatePlotPoints();
      updateInsideList();

      if (hist != null) {
        hist.setPlotPoints(plotPoints);
      }
    }
  }

  /**
   * Sets the horizontal and vertical limits
   * 
   * @param newXLim the new horizontal limits
   * @param newYLim the new vertical limits
   */
  public void setXYLim(float[] newXLim, float[] newYLim) {
    setXYLim(newXLim[0], newXLim[1], newYLim[0], newYLim[1]);
  }

  /**
   * Sets the horizontal and vertical limits and the horizontal and vertical scales
   * 
   * @param xMin the minimum horizontal limit value
   * @param xMax the maximum horizontal limit value
   * @param yMin the minimum vertical limit value
   * @param yMax the maximum vertical limit value
   * @param newXLog the new horizontal scale
   * @param newYLog the new vertical scale
   */
  public void setLimAndLog(float xMin, float xMax, float yMin, float yMax, boolean newXLog, boolean newYLog) {
    if (xMin != xMax && yMin != yMax && isValidNumber(xMin) && isValidNumber(xMax) && isValidNumber(yMin)
      && isValidNumber(yMax)) {
      // Make sure the new limits make sense
      if (newXLog && (xMin <= 0 || xMax <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        xLim[0] = xMin;
        yLim[1] = xMax;
        xLog = newXLog;
      }

      if (newYLog && (yMin <= 0 || yMax <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        yLim[0] = yMin;
        yLim[1] = yMax;
        yLog = newYLog;
      }

      updatePlotPoints();
      updateInsideList();

      if (hist != null) {
        hist.setPlotPoints(plotPoints);
      }
    }
  }

  /**
   * Sets the horizontal and vertical limits and the horizontal and vertical scales
   * 
   * @param newXLim the new horizontal limits
   * @param newYLim the new vertical limits
   * @param newXLog the new horizontal scale
   * @param newYLog the new vertical scale
   */
  public void setLimAndLog(float[] newXLim, float[] newYLim, boolean newXLog, boolean newYLog) {
    setLimAndLog(newXLim[0], newXLim[1], newYLim[0], newYLim[1], newXLog, newYLog);
  }

  /**
   * Sets the horizontal scale
   * 
   * @param newXLog the new horizontal scale
   */
  public void setXLog(boolean newXLog) {
    if (newXLog != xLog) {
      if (newXLog && (xLim[0] <= 0 || xLim[1] <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
        PApplet.println("Will set horizontal limits to (0.1, 10)");
        xLim[0] = 0.1f;
        xLim[1] = 10;
      }

      xLog = newXLog;
      updatePlotPoints();
      updateInsideList();

      if (hist != null) {
        hist.setPlotPoints(plotPoints);
      }
    }
  }

  /**
   * Sets the vertical scale
   * 
   * @param newYLog the new vertical scale
   */
  public void setYLog(boolean newYLog) {
    if (newYLog != yLog) {
      if (newYLog && (yLim[0] <= 0 || yLim[1] <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
        PApplet.println("Will set vertical limits to (0.1, 10)");
        yLim[0] = 0.1f;
        yLim[1] = 10;
      }

      yLog = newYLog;
      updatePlotPoints();
      updateInsideList();

      if (hist != null) {
        hist.setPlotPoints(plotPoints);
      }
    }
  }

  /**
   * Sets the layer points
   * 
   * @param newPoints the new points
   */
  public void setPoints(GPointsArray newPoints) {
    points.set(newPoints);
    updatePlotPoints();
    updateInsideList();

    if (hist != null) {
      hist.setPlotPoints(plotPoints);
    }
  }

  /**
   * Sets one of the layer points
   * 
   * @param index the point position
   * @param x the point new x coordinate
   * @param y the point new y coordinate
   * @param label the point new label
   */
  public void setPoint(int index, float x, float y, String label) {
    points.set(index, x, y, label);
    plotPoints.set(index, valueToXPlot(x), valueToYPlot(y), label);
    inside.set(index, isInside(plotPoints.get(index)));

    if (hist != null) {
      hist.setPlotPoint(index, plotPoints.get(index));
    }
  }

  /**
   * Sets one of the layer points
   * 
   * @param index the point position
   * @param x the point new x coordinate
   * @param y the point new y coordinate
   */
  public void setPoint(int index, float x, float y) {
    setPoint(index, x, y, points.getLabel(index));
  }

  /**
   * Sets one of the layer points
   * 
   * @param index the point position
   * @param newPoint the new point
   */
  public void setPoint(int index, GPoint newPoint) {
    setPoint(index, newPoint.getX(), newPoint.getY(), newPoint.getLabel());
  }

  /**
   * Adds a new point to the layer points
   * 
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   * @param label the new point label
   */
  public void addPoint(float x, float y, String label) {
    points.add(x, y, label);
    plotPoints.add(valueToXPlot(x), valueToYPlot(y), label);
    inside.add(isInside(plotPoints.getLastPoint()));

    if (hist != null) {
      hist.addPlotPoint(plotPoints.getLastPoint());
    }
  }

  /**
   * Adds a new point to the layer points
   * 
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   */
  public void addPoint(float x, float y) {
    addPoint(x, y, "");
  }

  /**
   * Adds a new point to the layer points
   * 
   * @param newPoint the point to add
   */
  public void addPoint(GPoint newPoint) {
    addPoint(newPoint.getX(), newPoint.getY(), newPoint.getLabel());
  }

  /**
   * Adds a new point to the layer points
   * 
   * @param index the position to add the point
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   * @param label the new point label
   */
  public void addPoint(int index, float x, float y, String label) {
    points.add(index, x, y, label);
    plotPoints.add(index, valueToXPlot(x), valueToYPlot(y), label);
    inside.add(index, isInside(plotPoints.get(index)));

    if (hist != null) {
      hist.addPlotPoint(index, plotPoints.get(index));
    }
  }

  /**
   * Adds a new point to the layer points
   * 
   * @param index the position to add the point
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   */
  public void addPoint(int index, float x, float y) {
    addPoint(index, x, y, "");
  }

  /**
   * Adds a new point to the layer points
   * 
   * @param index the position to add the point
   * @param newPoint the point to add
   */
  public void addPoint(int index, GPoint newPoint) {
    addPoint(index, newPoint.getX(), newPoint.getY(), newPoint.getLabel());
  }

  /**
   * Adds new points to the layer points
   * 
   * @param newPoints the points to add
   */
  public void addPoints(GPointsArray newPoints) {
    for (int i = 0; i < newPoints.getNPoints(); i++) {
      points.add(newPoints.get(i));
      plotPoints.add(valueToXPlot(newPoints.getX(i)), valueToYPlot(newPoints.getY(i)), newPoints.getLabel(i));
      inside.add(isInside(plotPoints.getLastPoint()));
    }

    if (hist != null) {
      hist.setPlotPoints(plotPoints);
    }
  }

  /**
   * Removes one of the layer points
   * 
   * @param index the point position
   */
  public void removePoint(int index) {
    points.remove(index);
    plotPoints.remove(index);
    inside.remove(index);

    if (hist != null) {
      hist.removePlotPoint(index);
    }
  }

  /**
   * Sets which points are inside the box
   * 
   * @param newInside a boolean array with the information whether a point is inside or not
   */
  public void setInside(boolean[] newInside) {
    if (newInside.length == inside.size()) {
      for (int i = 0; i < inside.size(); i++) {
        inside.set(i, newInside[i]);
      }
    }
  }

  /**
   * Sets the points colors
   * 
   * @param newPointColors the new point colors
   */
  public void setPointColors(int[] newPointColors) {
    if (newPointColors.length > 0) {
      pointColors = newPointColors.clone();
    }
  }

  /**
   * Sets the points color
   * 
   * @param newPointColor the new point color
   */
  public void setPointColor(int newPointColor) {
    pointColors = new int[] { newPointColor };
  }

  /**
   * Sets the points sizes
   * 
   * @param newPointSizes the new point sizes
   */
  public void setPointSizes(float[] newPointSizes) {
    if (newPointSizes.length > 0) {
      pointSizes = newPointSizes.clone();
    }
  }

  /**
   * Sets the points size
   * 
   * @param newPointSize the new point size
   */
  public void setPointSize(float newPointSize) {
    pointSizes = new float[] { newPointSize };
  }

  /**
   * Sets the line color
   * 
   * @param newLineColor the new line color
   */
  public void setLineColor(int newLineColor) {
    lineColor = newLineColor;
  }

  /**
   * Sets the line width
   * 
   * @param newLineWidth the new line width
   */
  public void setLineWidth(float newLineWidth) {
    if (newLineWidth > 0) {
      lineWidth = newLineWidth;
    }
  }

  /**
   * Sets the histogram base point
   * 
   * @param newHistBasePoint the new histogram base point
   */
  public void setHistBasePoint(GPoint newHistBasePoint) {
    histBasePoint.set(newHistBasePoint);
  }

  /**
   * Sets the histogram type
   * 
   * @param histType the new histogram type. It can be GPlot.HORIZONTAL or GPlot.VERTICAL
   */
  public void setHistType(int histType) {
    if (hist != null) {
      hist.setType(histType);
    }
  }

  /**
   * Sets if the histogram is visible or not
   * 
   * @param visible if true, the histogram is visible
   */
  public void setHistVisible(boolean visible) {
    if (hist != null) {
      hist.setVisible(visible);
    }
  }

  /**
   * Sets if the histogram labels will be drawn or not
   * 
   * @param drawHistLabels if true, the histogram labels will be drawn
   */
  public void setDrawHistLabels(boolean drawHistLabels) {
    if (hist != null) {
      hist.setDrawLabels(drawHistLabels);
    }
  }

  /**
   * Sets the label background color
   * 
   * @param newLabelBgColor the new label background color
   */
  public void setLabelBgColor(int newLabelBgColor) {
    labelBgColor = newLabelBgColor;
  }

  /**
   * Sets the label separation
   * 
   * @param newLabelSeparation the new label separation
   */
  public void setLabelSeparation(float[] newLabelSeparation) {
    labelSeparation[0] = newLabelSeparation[0];
    labelSeparation[1] = newLabelSeparation[1];
  }

  /**
   * Sets the font name
   * 
   * @param newFontName the name of the new font
   */
  public void setFontName(String newFontName) {
    fontName = newFontName;
    font = parent.createFont(fontName, fontSize);
  }

  /**
   * Sets the font color
   * 
   * @param newFontColor the new font color
   */
  public void setFontColor(int newFontColor) {
    fontColor = newFontColor;
  }

  /**
   * Sets the font size
   * 
   * @param newFontSize the new font size
   */
  public void setFontSize(int newFontSize) {
    if (newFontSize > 0) {
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }

  /**
   * Sets all the font properties at once
   * 
   * @param newFontName the name of the new font
   * @param newFontColor the new font color
   * @param newFontSize the new font size
   */
  public void setFontProperties(String newFontName, int newFontColor, int newFontSize) {
    if (newFontSize > 0) {
      fontName = newFontName;
      fontColor = newFontColor;
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }

  /**
   * Sets the font properties in the layer and the histogram
   * 
   * @param newFontName the new font name
   * @param newFontColor the new font color
   * @param newFontSize the new font size
   */
  public void setAllFontProperties(String newFontName, int newFontColor, int newFontSize) {
    setFontProperties(newFontName, newFontColor, newFontSize);

    if (hist != null) {
      hist.setFontProperties(newFontName, newFontColor, newFontSize);
    }
  }

  /**
   * Returns the layer id
   * 
   * @return the layer id
   */
  public String getId() {
    return id;
  }

  /**
   * Returns the layer dimensions
   * 
   * @return the layer dimensions
   */
  public float[] getDim() {
    return dim.clone();
  }

  /**
   * Returns the layer horizontal limits
   * 
   * @return the layer horizontal limits
   */
  public float[] getXLim() {
    return xLim.clone();
  }

  /**
   * Returns the layer vertical limits
   * 
   * @return the layer vertical limits
   */
  public float[] getYLim() {
    return yLim.clone();
  }

  /**
   * Returns the layer horizontal scale
   * 
   * @return the layer horizontal scale
   */
  public boolean getXLog() {
    return xLog;
  }

  /**
   * Returns the layer vertical scale
   * 
   * @return the layer vertical scale
   */
  public boolean getYLog() {
    return yLog;
  }

  /**
   * Returns a copy of the layer points
   * 
   * @return a copy of the layer points
   */
  public GPointsArray getPoints() {
    return new GPointsArray(points);
  }

  /**
   * Returns the layer points
   * 
   * @return the layer points
   */
  public GPointsArray getPointsRef() {
    return points;
  }

  /**
   * Returns the layer point colors array
   * 
   * @return the layer point colors array
   */
  public int[] getPointColors() {
    return pointColors.clone();
  }

  /**
   * Returns the layer point sizes array
   * 
   * @return the layer point sizes array
   */
  public float[] getPointSizes() {
    return pointSizes.clone();
  }

  /**
   * Returns the layer line color
   * 
   * @return the layer line color
   */
  public int getLineColor() {
    return lineColor;
  }

  /**
   * Returns the layer line width
   * 
   * @return the layer line width
   */
  public float getLineWidth() {
    return lineWidth;
  }

  /**
   * Returns the layer histogram
   * 
   * @return the layer histogram
   */
  public GHistogram getHistogram() {
    return hist;
  }
}

/**
 * ##library.name##
 * ##library.sentence##
 * ##library.url##
 *
 * Copyright ##copyright## ##author##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 *
 * @author      ##author##
 * @modified    ##date##
 * @version     ##library.prettyVersion## (##library.version##)
 */

//package grafica;

import java.util.ArrayList;
import processing.core.PApplet;
import processing.core.PConstants;
import processing.core.PImage;
import processing.core.PShape;
import processing.event.MouseEvent;

/**
 * Plot class. It controls the rest of the graphical elements (layers, axes, title, limits).
 *
 * @author ##author##
 */
public class GPlot implements PConstants {
  // The parent Processing applet
  protected final PApplet parent;

  // General properties
  protected float[] pos;
  protected float[] outerDim;
  protected float[] mar;
  protected float[] dim;
  protected float[] xLim;
  protected float[] yLim;
  protected boolean fixedXLim;
  protected boolean fixedYLim;
  protected boolean xLog;
  protected boolean yLog;
  protected boolean invertedXScale;
  protected boolean invertedYScale;
  protected boolean includeAllLayersInLim;
  protected float expandLimFactor;

  // Format properties
  protected int bgColor;
  protected int boxBgColor;
  protected int boxLineColor;
  protected float boxLineWidth;
  protected int gridLineColor;
  protected float gridLineWidth;

  // Layers
  protected final GLayer mainLayer;
  protected final ArrayList<GLayer> layerList;

  // Axes and title
  protected final GAxis xAxis;
  protected final GAxis topAxis;
  protected final GAxis yAxis;
  protected final GAxis rightAxis;
  protected final GTitle title;

  // Constants
  public static final String MAINLAYERID = "main layer";
  public static final int VERTICAL = 0;
  public static final int HORIZONTAL = 1;
  public static final int BOTH = 2;
  public static final int NONE = 0;
  public static final int ALTMOD = MouseEvent.ALT;
  public static final int CTRLMOD = MouseEvent.CTRL;
  public static final int METAMOD = MouseEvent.META;
  public static final int SHIFTMOD = MouseEvent.SHIFT;
  public static final float LOG10 = 2.30258509299; //(float) Math.log(10);

  // Mouse events
  protected boolean zoomingIsActive;
  protected float zoomFactor;
  protected int increaseZoomButton;
  protected int decreaseZoomButton;
  protected int increaseZoomKeyModifier;
  protected int decreaseZoomKeyModifier;
  protected boolean centeringIsActive;
  protected int centeringButton;
  protected int centeringKeyModifier;
  protected boolean panningIsActive;
  protected int panningButton;
  protected int panningKeyModifier;
  protected float[] panningReferencePoint;
  protected boolean labelingIsActive;
  protected int labelingButton;
  protected int labelingKeyModifier;
  protected float[] mousePos;
  protected boolean resetIsActive;
  protected int resetButton;
  protected int resetKeyModifier;
  protected float[] xLimReset;
  protected float[] yLimReset;

  /**
   * GPlot constructor
   *
   * @param parent the parent Processing applet
   * @param xPos the plot x position on the screen
   * @param yPos the plot y position on the screen
   * @param plotWidth the plot width (x outer dimension)
   * @param plotHeight the plot height (y outer dimension)
   */
  public GPlot(PApplet parent, float xPos, float yPos, float plotWidth, float plotHeight) {
    this.parent = parent;

    pos = new float[] { xPos, yPos };
    outerDim = new float[] { plotWidth, plotHeight };
    mar = new float[] { 60, 70, 40, 30 };
    dim = new float[] { outerDim[0] - mar[1] - mar[3], outerDim[1] - mar[0] - mar[2] };
    xLim = new float[] { 0, 1 };
    yLim = new float[] { 0, 1 };
    fixedXLim = false;
    fixedYLim = false;
    xLog = false;
    yLog = false;
    invertedXScale = false;
    invertedYScale = false;
    includeAllLayersInLim = true;
    expandLimFactor = 0.1f;

    bgColor = color(255);
    boxBgColor = color(245);
    boxLineColor = color(210);
    boxLineWidth = 1;
    gridLineColor = color(210);
    gridLineWidth = 1;

    mainLayer = new GLayer(this.parent, MAINLAYERID, dim, xLim, yLim, xLog, yLog);
    layerList = new ArrayList<GLayer>();

    xAxis = new GAxis(this.parent, X, dim, xLim, xLog);
    topAxis = new GAxis(this.parent, TOP, dim, xLim, xLog);
    yAxis = new GAxis(this.parent, Y, dim, yLim, yLog);
    rightAxis = new GAxis(this.parent, RIGHT, dim, yLim, yLog);
    title = new GTitle(this.parent, dim);

    // Setup for the mouse events
    this.parent.registerMethod("mouseEvent", this);
    zoomingIsActive = false;
    zoomFactor = 1.3f;
    increaseZoomButton = LEFT;
    decreaseZoomButton = RIGHT;
    increaseZoomKeyModifier = NONE;
    decreaseZoomKeyModifier = NONE;
    centeringIsActive = false;
    centeringButton = LEFT;
    centeringKeyModifier = NONE;
    panningIsActive = false;
    panningButton = LEFT;
    panningKeyModifier = NONE;
    panningReferencePoint = null;
    labelingIsActive = false;
    labelingButton = LEFT;
    labelingKeyModifier = NONE;
    mousePos = null;
    resetIsActive = false;
    resetButton = RIGHT;
    resetKeyModifier = CTRLMOD;
    xLimReset = null;
    yLimReset = null;
  }

  /**
   * GPlot constructor
   *
   * @param parent the parent Processing applet
   * @param xPos the plot x position on the screen
   * @param yPos the plot y position on the screen
   */
  public GPlot(PApplet parent, float xPos, float yPos) {
    this(parent, xPos, yPos, 450, 300);
  }

  /**
   * GPlot constructor
   *
   * @param parent the parent Processing applet
   */
  public GPlot(PApplet parent) {
    this(parent, 0, 0, 450, 300);
  }

  /**
   * Adds a layer to the plot
   *
   * @param newLayer the layer to add
   */
  public void addLayer(GLayer newLayer) {
    // Check that it is the only layer with that id
    String id = newLayer.getId();
    boolean sameId = false;

    if (mainLayer.isId(id)) {
      sameId = true;
    } else {
      for (int i = 0; i < layerList.size(); i++) {
        if (layerList.get(i).isId(id)) {
          sameId = true;
          break;
        }
      }
    }

    // Add the layer to the list
    if (!sameId) {
      newLayer.setDim(dim);
      newLayer.setLimAndLog(xLim, yLim, xLog, yLog);
      layerList.add(newLayer);

      // Calculate and update the new plot limits if necessary
      if (includeAllLayersInLim) {
        updateLimits();
      }
    } else {
      PApplet.println("A layer with the same id exists. Please change the id and try to add it again.");
    }
  }

  /**
   * Adds a new layer to the plot
   *
   * @param id the id to use for the new layer
   * @param points the points to be included in the layer
   */
  public void addLayer(String id, GPointsArray points) {
    // Check that it is the only layer with that id
    boolean sameId = false;

    if (mainLayer.isId(id)) {
      sameId = true;
    } else {
      for (int i = 0; i < layerList.size(); i++) {
        if (layerList.get(i).isId(id)) {
          sameId = true;
          break;
        }
      }
    }

    // Add the layer to the list
    if (!sameId) {
      GLayer newLayer = new GLayer(parent, id, dim, xLim, yLim, xLog, yLog);
      newLayer.setPoints(points);
      layerList.add(newLayer);

      // Calculate and update the new plot limits if necessary
      if (includeAllLayersInLim) {
        updateLimits();
      }
    } else {
      PApplet.println("A layer with the same id exists. Please change the id and try to add it again.");
    }
  }

  /**
   * Removes an exiting layer from the plot, provided it is not the plot main layer
   *
   * @param id the id of the layer to remove
   */
  public void removeLayer(String id) {
    int index = -1;

    for (int i = 0; i < layerList.size(); i++) {
      if (layerList.get(i).isId(id)) {
        index = i;
        break;
      }
    }

    if (index >= 0) {
      layerList.remove(index);

      // Calculate and update the new plot limits if necessary
      if (includeAllLayersInLim) {
        updateLimits();
      }
    } else {
      PApplet.println("Couldn't find a layer in the plot with id = " + id);
    }
  }

  /**
   * Calculates the position of a point in the screen, relative to the plot reference system
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   *
   * @return the x and y positions in the plot reference system
   */
  public float[] getPlotPosAt(float xScreen, float yScreen) {
    float xPlot = xScreen - (pos[0] + mar[1]);
    float yPlot = yScreen - (pos[1] + mar[2] + dim[1]);

    return new float[] { xPlot, yPlot };
  }

  /**
   * Calculates the position of a given (x, y) point in the parent Processing applet screen
   *
   * @param xValue the x value
   * @param yValue the y value
   *
   * @return the position of the (x, y) point in the parent Processing applet screen
   */
  public float[] getScreenPosAtValue(float xValue, float yValue) {
    float xScreen = mainLayer.valueToXPlot(xValue) + (pos[0] + mar[1]);
    float yScreen = mainLayer.valueToYPlot(yValue) + (pos[1] + mar[2] + dim[1]);

    return new float[] { xScreen, yScreen };
  }

  /**
   * Returns the closest point in the main layer to a given screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   *
   * @return the closest point in the plot main layer. Null if there is not a close point
   */
  public GPoint getPointAt(float xScreen, float yScreen) {
    float[] plotPos = getPlotPosAt(xScreen, yScreen);

    return mainLayer.getPointAtPlotPos(plotPos[0], plotPos[1]);
  }

  /**
   * Returns the closest point in the specified layer to a given screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   * @param layerId the layer id
   *
   * @return the closest point in the specified layer. Null if there is not a close point
   */
  public GPoint getPointAt(float xScreen, float yScreen, String layerId) {
    GPoint p = null;

    if (mainLayer.isId(layerId)) {
      p = getPointAt(xScreen, yScreen);
    } else {
      for (int i = 0; i < layerList.size(); i++) {
        if (layerList.get(i).isId(layerId)) {
          float[] plotPos = getPlotPosAt(xScreen, yScreen);
          p = layerList.get(i).getPointAtPlotPos(plotPos[0], plotPos[1]);
          break;
        }
      }
    }

    return p;
  }

  /**
   * Adds a point to the main layer at a given screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   */
  public void addPointAt(float xScreen, float yScreen) {
    float[] value = getValueAt(xScreen, yScreen);
    addPoint(value[0], value[1]);
  }

  /**
   * Adds a point to the specified layer at a given screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   * @param layerId the layer id
   */
  public void addPointAt(float xScreen, float yScreen, String layerId) {
    float[] value = getValueAt(xScreen, yScreen);
    addPoint(value[0], value[1], layerId);
  }

  /**
   * Removes a point from the main layer at a given screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   */
  public void removePointAt(float xScreen, float yScreen) {
    float[] plotPos = getPlotPosAt(xScreen, yScreen);
    int pointIndex = mainLayer.getPointIndexAtPlotPos(plotPos[0], plotPos[1]);

    if (pointIndex >= 0) {
      removePoint(pointIndex);
    }
  }

  /**
   * Removes a point from the specified layer at a given screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   * @param layerId the layer id
   */
  public void removePointAt(float xScreen, float yScreen, String layerId) {
    float[] plotPos = getPlotPosAt(xScreen, yScreen);
    int pointIndex = getLayer(layerId).getPointIndexAtPlotPos(plotPos[0], plotPos[1]);

    if (pointIndex >= 0) {
      removePoint(pointIndex, layerId);
    }
  }

  /**
   * Returns the plot value at a given screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   *
   * @return the plot value
   */
  public float[] getValueAt(float xScreen, float yScreen) {
    float[] plotPos = getPlotPosAt(xScreen, yScreen);

    return mainLayer.plotToValue(plotPos[0], plotPos[1]);
  }

  /**
   * Returns the relative plot position of a given screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   *
   * @return the relative position in the plot reference system
   */
  public float[] getRelativePlotPosAt(float xScreen, float yScreen) {
    float[] plotPos = getPlotPosAt(xScreen, yScreen);

    return new float[] { plotPos[0] / dim[0], -plotPos[1] / dim[1] };
  }

  /**
   * Indicates if a given screen position is inside the main plot area
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   *
   * @return true if the position is inside the main plot area
   */
  public boolean isOverPlot(float xScreen, float yScreen) {
    return (xScreen >= pos[0]) && (xScreen <= pos[0] + outerDim[0]) && (yScreen >= pos[1])
      && (yScreen <= pos[1] + outerDim[1]);
  }

  /**
   * Indicates if a given screen position is inside the plot box area
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   *
   * @return true if the position is inside the plot box area
   */
  public boolean isOverBox(float xScreen, float yScreen) {
    return (xScreen >= pos[0] + mar[1]) && (xScreen <= pos[0] + outerDim[0] - mar[3])
      && (yScreen >= pos[1] + mar[2]) && (yScreen <= pos[1] + outerDim[1] - mar[0]);
  }

  /**
   * Calculates and updates the plot x and y limits
   */
  public void updateLimits() {
    // Calculate the new limits and update the axes if needed
    if (!fixedXLim) {
      xLim = calculatePlotXLim();
      xAxis.setLim(xLim);
      topAxis.setLim(xLim);
    }

    if (!fixedYLim) {
      yLim = calculatePlotYLim();
      yAxis.setLim(yLim);
      rightAxis.setLim(yLim);
    }

    // Update the layers
    mainLayer.setXYLim(xLim, yLim);

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).setXYLim(xLim, yLim);
    }
  }

  /**
   * Calculates the plot x limits
   *
   * @return the x limits
   */
  protected float[] calculatePlotXLim() {
    // Find the limits for the main layer
    float[] lim = calculatePointsXLim(mainLayer.getPointsRef());

    // Include the other layers in the limit calculation if necessary
    if (includeAllLayersInLim) {
      for (int i = 0; i < layerList.size(); i++) {
        float[] newLim = calculatePointsXLim(layerList.get(i).getPointsRef());

        if (newLim != null) {
          if (lim != null) {
            lim[0] = PApplet.min(lim[0], newLim[0]);
            lim[1] = PApplet.max(lim[1], newLim[1]);
          } else {
            lim = newLim;
          }
        }
      }
    }

    if (lim != null) {
      // Expand the axis limits a bit
      float delta = (lim[0] == 0) ? 0.1f : 0.1f * lim[0];

      if (xLog) {
        if (lim[0] != lim[1]) {
          delta = PApplet.exp(expandLimFactor * PApplet.log(lim[1] / lim[0]));
        }

        lim[0] = lim[0] / delta;
        lim[1] = lim[1] * delta;
      } else {
        if (lim[0] != lim[1]) {
          delta = expandLimFactor * (lim[1] - lim[0]);
        }

        lim[0] = lim[0] - delta;
        lim[1] = lim[1] + delta;
      }
    } else {
      if (xLog && (xLim[0] <= 0 || xLim[1] <= 0)) {
        lim = new float[] { 0.1f, 10 };
      } else {
        lim = xLim;
      }
    }

    // Invert the limits if necessary
    if (invertedXScale && lim[0] < lim[1]) {
      lim = new float[] { lim[1], lim[0] };
    }

    return lim;
  }

  /**
   * Calculates the plot y limits
   *
   * @return the y limits
   */
  protected float[] calculatePlotYLim() {
    // Find the limits for the main layer
    float[] lim = calculatePointsYLim(mainLayer.getPointsRef());

    // Include the other layers in the limit calculation if necessary
    if (includeAllLayersInLim) {
      for (int i = 0; i < layerList.size(); i++) {
        float[] newLim = calculatePointsYLim(layerList.get(i).getPointsRef());

        if (newLim != null) {
          if (lim != null) {
            lim[0] = PApplet.min(lim[0], newLim[0]);
            lim[1] = PApplet.max(lim[1], newLim[1]);
          } else {
            lim = newLim;
          }
        }
      }
    }

    if (lim != null) {
      // Expand the axis limits a bit
      float delta = (lim[0] == 0) ? 0.1f : 0.1f * lim[0];

      if (yLog) {
        if (lim[0] != lim[1]) {
          delta = PApplet.exp(expandLimFactor * PApplet.log(lim[1] / lim[0]));
        }

        lim[0] = lim[0] / delta;
        lim[1] = lim[1] * delta;
      } else {
        if (lim[0] != lim[1]) {
          delta = expandLimFactor * (lim[1] - lim[0]);
        }

        lim[0] = lim[0] - delta;
        lim[1] = lim[1] + delta;
      }
    } else {
      if (yLog && (yLim[0] <= 0 || yLim[1] <= 0)) {
        lim = new float[] { 0.1f, 10 };
      } else {
        lim = yLim;
      }
    }

    // Invert the limits if necessary
    if (invertedYScale && lim[0] < lim[1]) {
      lim = new float[] { lim[1], lim[0] };
    }

    return lim;
  }

  /**
   * Calculates the x limits of a given set of points, considering the plot properties (axis log scale, if the other
   * axis limits are fixed, etc)
   *
   * @param points the points for which we want to calculate the x limits
   *
   * @return the x limits. Null if none of the points satisfies the plot properties
   */
  public float[] calculatePointsXLim(GPointsArray points) {
    // Find the points limits
    float[] lim = new float[] { Float.MAX_VALUE, -Float.MAX_VALUE };

    for (int i = 0; i < points.getNPoints(); i++) {
      if (points.isValid(i)) {
        // Use the point if it's inside, and it's not negative if
        // the scale is logarithmic
        float x = points.getX(i);
        float y = points.getY(i);
        boolean isInside = true;

        if (fixedYLim) {
          isInside = ((yLim[1] >= yLim[0]) && (y >= yLim[0]) && (y <= yLim[1]))
            || ((yLim[1] < yLim[0]) && (y <= yLim[0]) && (y >= yLim[1]));
        }

        if (isInside && !(xLog && x <= 0)) {
          if (x < lim[0]) {
            lim[0] = x;
          }
          if (x > lim[1]) {
            lim[1] = x;
          }
        }
      }
    }

    // Check that the new limits make sense
    if (lim[1] < lim[0]) {
      lim = null;
    }

    return lim;
  }

  /**
   * Calculates the y limits of a given set of points, considering the plot properties (axis log scale, if the other
   * axis limits are fixed, etc)
   *
   * @param points the points for which we want to calculate the y limSits
   *
   * @return the y limits. Null if none of the points satisfies the plot properties
   */
  public float[] calculatePointsYLim(GPointsArray points) {
    // Find the points limits
    float[] lim = new float[] { Float.MAX_VALUE, -Float.MAX_VALUE };

    for (int i = 0; i < points.getNPoints(); i++) {
      if (points.isValid(i)) {
        // Use the point if it's inside, and it's not negative if
        // the scale is logarithmic
        float x = points.getX(i);
        float y = points.getY(i);
        boolean isInside = true;

        if (fixedXLim) {
          isInside = ((xLim[1] >= xLim[0]) && (x >= xLim[0]) && (x <= xLim[1]))
            || ((xLim[1] < xLim[0]) && (x <= xLim[0]) && (x >= xLim[1]));
        }

        if (isInside && !(yLog && y <= 0)) {
          if (y < lim[0]) {
            lim[0] = y;
          }
          if (y > lim[1]) {
            lim[1] = y;
          }
        }
      }
    }

    // Check that the new limits make sense
    if (lim[1] < lim[0]) {
      lim = null;
    }

    return lim;
  }

  /**
   * Moves the horizontal axes limits by a given amount specified in pixel units
   *
   * @param delta pixels to move
   */
  public void moveHorizontalAxesLim(float delta) {
    // Obtain the new x limits
    if (xLog) {
      float deltaLim = PApplet.exp(PApplet.log(xLim[1] / xLim[0]) * delta / dim[0]);
      xLim[0] *= deltaLim;
      xLim[1] *= deltaLim;
    } else {
      float deltaLim = (xLim[1] - xLim[0]) * delta / dim[0];
      xLim[0] += deltaLim;
      xLim[1] += deltaLim;
    }

    // Fix the limits
    fixedXLim = true;
    fixedYLim = true;

    // Move the horizontal axes
    xAxis.moveLim(xLim);
    topAxis.moveLim(xLim);

    // Update the plot limits
    updateLimits();
  }

  /**
   * Moves the vertical axes limits by a given amount specified in pixel units
   *
   * @param delta pixels to move
   */
  public void moveVerticalAxesLim(float delta) {
    // Obtain the new y limits
    if (yLog) {
      float deltaLim = PApplet.exp(PApplet.log(yLim[1] / yLim[0]) * delta / dim[1]);
      yLim[0] *= deltaLim;
      yLim[1] *= deltaLim;
    } else {
      float deltaLim = (yLim[1] - yLim[0]) * delta / dim[1];
      yLim[0] += deltaLim;
      yLim[1] += deltaLim;
    }

    // Fix the limits
    fixedXLim = true;
    fixedYLim = true;

    // Move the vertical axes
    yAxis.moveLim(yLim);
    rightAxis.moveLim(yLim);

    // Update the plot limits
    updateLimits();
  }

  /**
   * Centers the plot coordinates on the specified (x, y) point and zooms the limits range by a given factor
   *
   * @param factor the plot limits will be zoomed by this factor
   * @param xValue the x plot value
   * @param yValue the y plot value
   */
  public void centerAndZoom(float factor, float xValue, float yValue) {
    // Calculate the new limits
    if (xLog) {
      float deltaLim = PApplet.exp(PApplet.log(xLim[1] / xLim[0]) / (2 * factor));
      xLim = new float[] { xValue / deltaLim, xValue * deltaLim };
    } else {
      float deltaLim = (xLim[1] - xLim[0]) / (2 * factor);
      xLim = new float[] { xValue - deltaLim, xValue + deltaLim };
    }

    if (yLog) {
      float deltaLim = PApplet.exp(PApplet.log(yLim[1] / yLim[0]) / (2 * factor));
      yLim = new float[] { yValue / deltaLim, yValue * deltaLim };
    } else {
      float deltaLim = (yLim[1] - yLim[0]) / (2 * factor);
      yLim = new float[] { yValue - deltaLim, yValue + deltaLim };
    }

    // Fix the limits
    fixedXLim = true;
    fixedYLim = true;

    // Update the horizontal and vertical axes
    xAxis.setLim(xLim);
    topAxis.setLim(xLim);
    yAxis.setLim(yLim);
    rightAxis.setLim(yLim);

    // Update the plot limits (the layers, because the limits are fixed)
    updateLimits();
  }

  /**
   * Zooms the limits range by a given factor
   *
   * @param factor the plot limits will be zoomed by this factor
   */
  public void zoom(float factor) {
    float[] centerValue = mainLayer.plotToValue(dim[0] / 2, -dim[1] / 2);

    centerAndZoom(factor, centerValue[0], centerValue[1]);
  }

  /**
   * Zooms the limits range by a given factor keeping the same plot value at the specified screen position
   *
   * @param factor the plot limits will be zoomed by this factor
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   */
  public void zoom(float factor, float xScreen, float yScreen) {
    float[] plotPos = getPlotPosAt(xScreen, yScreen);
    float[] value = mainLayer.plotToValue(plotPos[0], plotPos[1]);

    if (xLog) {
      float deltaLim = PApplet.exp(PApplet.log(xLim[1] / xLim[0]) / (2 * factor));
      float offset = PApplet.exp((PApplet.log(xLim[1] / xLim[0]) / factor) * (0.5f - plotPos[0] / dim[0]));
      xLim = new float[] { value[0] * offset / deltaLim, value[0] * offset * deltaLim };
    } else {
      float deltaLim = (xLim[1] - xLim[0]) / (2 * factor);
      float offset = 2 * deltaLim * (0.5f - plotPos[0] / dim[0]);
      xLim = new float[] { value[0] + offset - deltaLim, value[0] + offset + deltaLim };
    }

    if (yLog) {
      float deltaLim = PApplet.exp(PApplet.log(yLim[1] / yLim[0]) / (2 * factor));
      float offset = PApplet.exp((PApplet.log(yLim[1] / yLim[0]) / factor) * (0.5f + plotPos[1] / dim[1]));
      yLim = new float[] { value[1] * offset / deltaLim, value[1] * offset * deltaLim };
    } else {
      float deltaLim = (yLim[1] - yLim[0]) / (2 * factor);
      float offset = 2 * deltaLim * (0.5f + plotPos[1] / dim[1]);
      yLim = new float[] { value[1] + offset - deltaLim, value[1] + offset + deltaLim };
    }

    // Fix the limits
    fixedXLim = true;
    fixedYLim = true;

    // Update the horizontal and vertical axes
    xAxis.setLim(xLim);
    topAxis.setLim(xLim);
    yAxis.setLim(yLim);
    rightAxis.setLim(yLim);

    // Update the plot limits (the layers, because the limits are fixed)
    updateLimits();
  }

  /**
   * Shifts the plot coordinates in a way that the value at a given plot position will have after that the specified
   * new plot position
   *
   * @param valuePlotPos current plot position of the value
   * @param newPlotPos new plot position of the value
   */
  protected void shiftPlotPos(float[] valuePlotPos, float[] newPlotPos) {
    // Calculate the new limits
    float deltaXPlot = valuePlotPos[0] - newPlotPos[0];
    float deltaYPlot = valuePlotPos[1] - newPlotPos[1];

    if (xLog) {
      float deltaLim = PApplet.exp(PApplet.log(xLim[1] / xLim[0]) * deltaXPlot / dim[0]);
      xLim = new float[] { xLim[0] * deltaLim, xLim[1] * deltaLim };
    } else {
      float deltaLim = (xLim[1] - xLim[0]) * deltaXPlot / dim[0];
      xLim = new float[] { xLim[0] + deltaLim, xLim[1] + deltaLim };
    }

    if (yLog) {
      float deltaLim = PApplet.exp(-PApplet.log(yLim[1] / yLim[0]) * deltaYPlot / dim[1]);
      yLim = new float[] { yLim[0] * deltaLim, yLim[1] * deltaLim };
    } else {
      float deltaLim = -(yLim[1] - yLim[0]) * deltaYPlot / dim[1];
      yLim = new float[] { yLim[0] + deltaLim, yLim[1] + deltaLim };
    }

    // Fix the limits
    fixedXLim = true;
    fixedYLim = true;

    // Move the horizontal and vertical axes
    xAxis.moveLim(xLim);
    topAxis.moveLim(xLim);
    yAxis.moveLim(yLim);
    rightAxis.moveLim(yLim);

    // Update the plot limits (the layers, because the limits are fixed)
    updateLimits();
  }

  /**
   * Shifts the plot coordinates in a way that after that the given plot value will be at the specified screen
   * position
   *
   * @param xValue the x plot value
   * @param yValue the y plot value
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   */
  public void align(float xValue, float yValue, float xScreen, float yScreen) {
    float[] valuePlotPos = mainLayer.valueToPlot(xValue, yValue);
    float[] newPlotPos = getPlotPosAt(xScreen, yScreen);

    shiftPlotPos(valuePlotPos, newPlotPos);
  }

  /**
   * Shifts the plot coordinates in a way that after that the given plot value will be at the specified screen
   * position
   *
   * @param value the x and y plot values
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   */
  public void align(float[] value, float xScreen, float yScreen) {
    align(value[0], value[1], xScreen, yScreen);
  }

  /**
   * Centers the plot coordinates at the plot value that is at the specified screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   */
  public void center(float xScreen, float yScreen) {
    float[] valuePlotPos = getPlotPosAt(xScreen, yScreen);
    float[] newPlotPos = new float[] { dim[0] / 2, -dim[1] / 2 };

    shiftPlotPos(valuePlotPos, newPlotPos);
  }

  /**
   * Initializes the histograms in all the plot layers
   *
   * @param histType the type of histogram to use. It can be GPlot.VERTICAL or GPlot.HORIZONTAL
   */
  public void startHistograms(int histType) {
    mainLayer.startHistogram(histType);

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).startHistogram(histType);
    }
  }

  /**
   * Draws the plot on the screen with default parameters
   */
  public void defaultDraw() {
    beginDraw();
    drawBackground();
    drawBox();
    drawXAxis();
    drawYAxis();
    drawTitle();
    drawLines();
    drawPoints();
    endDraw();
  }

  /**
   * Prepares the environment to start drawing the different plot components (points, axes, title, etc). Use endDraw()
   * to return the sketch to its original state
   */
  public void beginDraw() {
    parent.pushStyle();
    parent.pushMatrix();
    parent.translate(pos[0] + mar[1], pos[1] + mar[2] + dim[1]);
  }

  /**
   * Returns the sketch to the state that it had before calling beginDraw()
   */
  public void endDraw() {
    parent.popMatrix();
    parent.popStyle();
  }

  /**
   * Draws the plot background. This includes the box area and the margins
   */
  public void drawBackground() {
    parent.pushStyle();
    parent.rectMode(CORNER);
    parent.fill(bgColor);
    parent.noStroke();
    parent.rect(-mar[1], -mar[2] - dim[1], outerDim[0], outerDim[1]);
    parent.popStyle();
  }

  /**
   * Draws the box area. This doesn't include the plot margins
   */
  public void drawBox() {
    parent.pushStyle();
    parent.rectMode(CORNER);
    parent.fill(boxBgColor);
    parent.stroke(boxLineColor);
    parent.strokeWeight(boxLineWidth);
    parent.strokeCap(SQUARE);
    parent.rect(0, -dim[1], dim[0], dim[1]);
    parent.popStyle();
  }

  /**
   * Draws the x axis
   */
  public void drawXAxis() {
    xAxis.draw();
  }

  /**
   * Draws the top axis
   */
  public void drawTopAxis() {
    topAxis.draw();
  }

  /**
   * Draws the y axis
   */
  public void drawYAxis() {
    yAxis.draw();
  }

  /**
   * Draws the right axis
   */
  public void drawRightAxis() {
    rightAxis.draw();
  }

  /**
   * Draws the title
   */
  public void drawTitle() {
    title.draw();
  }

  /**
   * Draws the points from all layers in the plot
   */
  public void drawPoints() {
    mainLayer.drawPoints();

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).drawPoints();
    }
  }

  /**
   * Draws the points from all layers in the plot
   *
   * @param pointShape the shape that should be used to represent the points
   */
  public void drawPoints(PShape pointShape) {
    mainLayer.drawPoints(pointShape);

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).drawPoints(pointShape);
    }
  }

  /**
   * Draws the points from all layers in the plot
   *
   * @param pointImg the image that should be used to represent the points
   */
  public void drawPoints(PImage pointImg) {
    mainLayer.drawPoints(pointImg);

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).drawPoints(pointImg);
    }
  }

  /**
   * Draws a point in the plot
   *
   * @param point the point to draw
   * @param pointColor color to use
   * @param pointSize point size in pixels
   */
  public void drawPoint(GPoint point, int pointColor, float pointSize) {
    mainLayer.drawPoint(point, pointColor, pointSize);
  }

  /**
   * Draws a point in the plot
   *
   * @param point the point to draw
   */
  public void drawPoint(GPoint point) {
    mainLayer.drawPoint(point);
  }

  /**
   * Draws a point in the plot
   *
   * @param point the point to draw
   * @param pointShape the shape that should be used to represent the point
   */
  public void drawPoint(GPoint point, PShape pointShape) {
    mainLayer.drawPoint(point, pointShape);
  }

  /**
   * Draws a point in the plot
   *
   * @param point the point to draw
   * @param pointShape the shape that should be used to represent the points
   * @param pointColor color to use
   */
  public void drawPoint(GPoint point, PShape pointShape, int pointColor) {
    mainLayer.drawPoint(point, pointShape, pointColor);
  }

  /**
   * Draws a point in the plot
   *
   * @param point the point to draw
   * @param pointImg the image that should be used to represent the point
   */
  public void drawPoint(GPoint point, PImage pointImg) {
    mainLayer.drawPoint(point, pointImg);
  }

  /**
   * Draws lines connecting the points from all layers in the plot
   */
  public void drawLines() {
    mainLayer.drawLines();

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).drawLines();
    }
  }

  /**
   * Draws a line in the plot, defined by two extreme points
   *
   * @param point1 first point
   * @param point2 second point
   * @param lineColor line color
   * @param lineWidth line width
   */
  public void drawLine(GPoint point1, GPoint point2, int lineColor, float lineWidth) {
    mainLayer.drawLine(point1, point2, lineColor, lineWidth);
  }

  /**
   * Draws a line in the plot, defined by two extreme points
   *
   * @param point1 first point
   * @param point2 second point
   */
  public void drawLine(GPoint point1, GPoint point2) {
    mainLayer.drawLine(point1, point2);
  }

  /**
   * Draws a line in the plot, defined by the slope and the cut in the y axis
   *
   * @param slope the line slope
   * @param yCut the line y axis cut
   * @param lineColor line color
   * @param lineWidth line width
   */
  public void drawLine(float slope, float yCut, int lineColor, float lineWidth) {
    mainLayer.drawLine(slope, yCut, lineColor, lineWidth);
  }

  /**
   * Draws a line in the plot, defined by the slope and the cut in the y axis
   *
   * @param slope the line slope
   * @param yCut the line y axis cut
   */
  public void drawLine(float slope, float yCut) {
    mainLayer.drawLine(slope, yCut);
  }

  /**
   * Draws an horizontal line in the plot
   *
   * @param value line horizontal value
   * @param lineColor line color
   * @param lineWidth line width
   */
  public void drawHorizontalLine(float value, int lineColor, float lineWidth) {
    mainLayer.drawHorizontalLine(value, lineColor, lineWidth);
  }

  /**
   * Draws an horizontal line in the plot
   *
   * @param value line horizontal value
   */
  public void drawHorizontalLine(float value) {
    mainLayer.drawHorizontalLine(value);
  }

  /**
   * Draws a vertical line in the plot
   *
   * @param value line vertical value
   * @param lineColor line color
   * @param lineWidth line width
   */
  public void drawVerticalLine(float value, int lineColor, float lineWidth) {
    mainLayer.drawVerticalLine(value, lineColor, lineWidth);
  }

  /**
   * Draws a vertical line in the plot
   *
   * @param value line vertical value
   */
  public void drawVerticalLine(float value) {
    mainLayer.drawVerticalLine(value);
  }

  /**
   * Draws filled contours connecting the points from all layers in the plot and a reference value
   *
   * @param contourType the type of contours to use. It can be GPlot.VERTICAL or GPlot.HORIZONTAL
   * @param referenceValue the reference value to use to close the contour
   */
  public void drawFilledContours(int contourType, float referenceValue) {
    mainLayer.drawFilledContour(contourType, referenceValue);

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).drawFilledContour(contourType, referenceValue);
    }
  }

  /**
   * Draws the label of a given point
   *
   * @param point the point
   */
  public void drawLabel(GPoint point) {
    mainLayer.drawLabel(point);
  }

  /**
   * Draws the labels of the points in the layers that are close to a given screen position
   *
   * @param xScreen x screen position in the parent Processing applet
   * @param yScreen y screen position in the parent Processing applet
   */
  public void drawLabelsAt(float xScreen, float yScreen) {
    float[] plotPos = getPlotPosAt(xScreen, yScreen);
    mainLayer.drawLabelAtPlotPos(plotPos[0], plotPos[1]);

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).drawLabelAtPlotPos(plotPos[0], plotPos[1]);
    }
  }

  /**
   * Draws the labels of the points in the layers that are close to the mouse position. In order to work, you need to
   * activate first the points labeling with the command plot.activatePointLabels()
   */
  public void drawLabels() {
    if (labelingIsActive && mousePos != null) {
      drawLabelsAt(mousePos[0], mousePos[1]);
    }
  }

  /**
   * Draws lines connecting the horizontal and vertical axis ticks
   *
   * @param gridType the type of grid to use. It could be GPlot.HORIZONTAL, GPlot.VERTICAL or GPlot.BOTH
   */
  public void drawGridLines(int gridType) {
    parent.pushStyle();
    parent.noFill();
    parent.stroke(gridLineColor);
    parent.strokeWeight(gridLineWidth);
    parent.strokeCap(SQUARE);

    if (gridType == BOTH || gridType == VERTICAL) {
      ArrayList<Float> xPlotTicks = xAxis.getPlotTicksRef();

      for (int i = 0; i < xPlotTicks.size(); i++) {
        if (xPlotTicks.get(i) >= 0 && xPlotTicks.get(i) <= dim[0]) {
          parent.line(xPlotTicks.get(i), 0, xPlotTicks.get(i), -dim[1]);
        }
      }
    }

    if (gridType == BOTH || gridType == HORIZONTAL) {
      ArrayList<Float> yPlotTicks = yAxis.getPlotTicksRef();

      for (int i = 0; i < yPlotTicks.size(); i++) {
        if (-yPlotTicks.get(i) >= 0 && -yPlotTicks.get(i) <= dim[1]) {
          parent.line(0, yPlotTicks.get(i), dim[0], yPlotTicks.get(i));
        }
      }
    }

    parent.popStyle();
  }

  /**
   * Draws the histograms of all layers
   */
  public void drawHistograms() {
    mainLayer.drawHistogram();

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).drawHistogram();
    }
  }

  /**
   * Draws a polygon defined by a set of points
   *
   * @param polygonPoints the points that define the polygon
   * @param polygonColor the color to use to draw the polygon (contour and background)
   */
  public void drawPolygon(GPointsArray polygonPoints, int polygonColor) {
    mainLayer.drawPolygon(polygonPoints, polygonColor);
  }

  /**
   * Draws an annotation at a given plot value
   *
   * @param text the annotation text
   * @param x x plot value
   * @param y y plot value
   * @param horAlign text horizontal alignment. It can be RIGHT, LEFT or CENTER
   * @param verAlign text vertical alignment. It can be TOP, BOTTOM or CENTER
   */
  public void drawAnnotation(String text, float x, float y, int horAlign, int verAlign) {
    mainLayer.drawAnnotation(text, x, y, horAlign, verAlign);
  }

  /**
   * Draws a legend at the specified relative position
   *
   * @param text the text to use for each layer in the plot
   * @param xRelativePos the plot x relative position for each layer in the plot
   * @param yRelativePos the plot y relative position for each layer in the plot
   */
  public void drawLegend(String[] text, float[] xRelativePos, float[] yRelativePos) {
    parent.pushStyle();
    parent.rectMode(CENTER);
    parent.noStroke();

    for (int i = 0; i < text.length; i++) {
      float[] plotPosition = new float[] { xRelativePos[i] * dim[0], -yRelativePos[i] * dim[1] };
      float[] position = mainLayer.plotToValue(plotPosition[0], plotPosition[1]);

      if (i == 0) {
        parent.fill(mainLayer.getLineColor());
        parent.rect(plotPosition[0] - 15, plotPosition[1], 14, 14);
        mainLayer.drawAnnotation(text[i], position[0], position[1], LEFT, CENTER);
      } else {
        parent.fill(layerList.get(i - 1).getLineColor());
        parent.rect(plotPosition[0] - 15, plotPosition[1], 14, 14);
        layerList.get(i - 1).drawAnnotation(text[i], position[0], position[1], LEFT, CENTER);
      }
    }

    parent.popStyle();
  }

  /**
   * Sets the plot position
   *
   * @param x the new plot x position on the screen
   * @param y the new plot y position on the screen
   */
  public void setPos(float x, float y) {
    pos[0] = x;
    pos[1] = y;
  }

  /**
   * Sets the plot position
   *
   * @param newPos the new plot (x, y) position
   */
  public void setPos(float[] newPos) {
    setPos(newPos[0], newPos[1]);
  }

  /**
   * Sets the plot outer dimensions
   *
   * @param xOuterDim the new plot x outer dimension
   * @param yOuterDim the new plot y outer dimension
   */
  public void setOuterDim(float xOuterDim, float yOuterDim) {
    if (xOuterDim > 0 && yOuterDim > 0) {
      // Make sure that the new plot dimensions are positive
      float xDim = xOuterDim - mar[1] - mar[3];
      float yDim = yOuterDim - mar[0] - mar[2];

      if (xDim > 0 && yDim > 0) {
        outerDim[0] = xOuterDim;
        outerDim[1] = yOuterDim;
        dim[0] = xDim;
        dim[1] = yDim;
        xAxis.setDim(dim);
        topAxis.setDim(dim);
        yAxis.setDim(dim);
        rightAxis.setDim(dim);
        title.setDim(dim);

        // Update the layers
        mainLayer.setDim(dim);

        for (int i = 0; i < layerList.size(); i++) {
          layerList.get(i).setDim(dim);
        }
      }
    }
  }

  /**
   * Sets the plot outer dimensions
   *
   * @param newOuterDim the new plot outer dimensions
   */
  public void setOuterDim(float[] newOuterDim) {
    setOuterDim(newOuterDim[0], newOuterDim[1]);
  }

  /**
   * Sets the plot margins
   *
   * @param bottomMargin the new plot bottom margin
   * @param leftMargin the new plot left margin
   * @param topMargin the new plot top margin
   * @param rightMargin the new plot right margin
   */
  public void setMar(float bottomMargin, float leftMargin, float topMargin, float rightMargin) {
    // Make sure that the new outer dimensions are positive
    float xOuterDim = dim[0] + leftMargin + rightMargin;
    float yOuterDim = dim[1] + bottomMargin + topMargin;

    if (xOuterDim > 0 && yOuterDim > 0) {
      mar[0] = bottomMargin;
      mar[1] = leftMargin;
      mar[2] = topMargin;
      mar[3] = rightMargin;
      outerDim[0] = xOuterDim;
      outerDim[1] = yOuterDim;
    }
  }

  /**
   * Sets the plot margins
   *
   * @param newMar the new plot margins
   */
  public void setMar(float[] newMar) {
    setMar(newMar[0], newMar[1], newMar[2], newMar[3]);
  }

  /**
   * Sets the plot box dimensions
   *
   * @param xDim the new plot box x dimension
   * @param yDim the new plot box y dimension
   */
  public void setDim(float xDim, float yDim) {
    if (xDim > 0 && yDim > 0) {
      // Make sure that the new outer dimensions are positive
      float xOuterDim = xDim + mar[1] + mar[3];
      float yOuterDim = yDim + mar[0] + mar[2];

      if (xOuterDim > 0 && yOuterDim > 0) {
        outerDim[0] = xOuterDim;
        outerDim[1] = yOuterDim;
        dim[0] = xDim;
        dim[1] = yDim;
        xAxis.setDim(dim);
        topAxis.setDim(dim);
        yAxis.setDim(dim);
        rightAxis.setDim(dim);
        title.setDim(dim);

        // Update the layers
        mainLayer.setDim(dim);

        for (int i = 0; i < layerList.size(); i++) {
          layerList.get(i).setDim(dim);
        }
      }
    }
  }

  /**
   * Sets the plot box dimensions
   *
   * @param newDim the new plot box dimensions
   */
  public void setDim(float[] newDim) {
    setDim(newDim[0], newDim[1]);
  }

  /**
   * Sets the horizontal axes limits
   *
   * @param lowerLim the new axes lower limit
   * @param upperLim the new axes upper limit
   */
  public void setXLim(float lowerLim, float upperLim) {
    if (lowerLim != upperLim) {
      // Make sure the new limits makes sense
      if (xLog && (lowerLim <= 0 || upperLim <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        xLim[0] = lowerLim;
        xLim[1] = upperLim;
        invertedXScale = xLim[0] > xLim[1];

        // Fix the limits
        fixedXLim = true;

        // Update the axes
        xAxis.setLim(xLim);
        topAxis.setLim(xLim);

        // Update the plot limits
        updateLimits();
      }
    }
  }

  /**
   * Sets the horizontal axes limits
   *
   * @param newXLim the new horizontal axes limits
   */
  public void setXLim(float[] newXLim) {
    setXLim(newXLim[0], newXLim[1]);
  }

  /**
   * Sets the vertical axes limits
   *
   * @param lowerLim the new axes lower limit
   * @param upperLim the new axes upper limit
   */
  public void setYLim(float lowerLim, float upperLim) {
    if (lowerLim != upperLim) {
      // Make sure the new limits makes sense
      if (yLog && (lowerLim <= 0 || upperLim <= 0)) {
        PApplet.println("One of the limits is negative. This is not allowed in logarithmic scale.");
      } else {
        yLim[0] = lowerLim;
        yLim[1] = upperLim;
        invertedYScale = yLim[0] > yLim[1];

        // Fix the limits
        fixedYLim = true;

        // Update the axes
        yAxis.setLim(yLim);
        rightAxis.setLim(yLim);

        // Update the plot limits
        updateLimits();
      }
    }
  }

  /**
   * Sets the vertical axes limits
   *
   * @param newYLim the new vertical axes limits
   */
  public void setYLim(float[] newYLim) {
    setYLim(newYLim[0], newYLim[1]);
  }

  /**
   * Sets if the horizontal axes limits are fixed or not
   *
   * @param newFixedXLim the fixed condition for the horizontal axes
   */
  public void setFixedXLim(boolean newFixedXLim) {
    fixedXLim = newFixedXLim;

    // Update the plot limits
    updateLimits();
  }

  /**
   * Sets if the vertical axes limits are fixed or not
   *
   * @param newFixedYLim the fixed condition for the vertical axes
   */
  public void setFixedYLim(boolean newFixedYLim) {
    fixedYLim = newFixedYLim;

    // Update the plot limits
    updateLimits();
  }

  /**
   * Sets if the scale for the horizontal and vertical axes is logarithmic or not
   *
   * @param logType the type of scale for the horizontal and vertical axes
   */
  public void setLogscale(String logType) {
    boolean newXLog = xLog;
    boolean newYLog = yLog;

    if (logType.equals("xy") || logType.equals("yx")) {
      newXLog = true;
      newYLog = true;
    } else if (logType.equals("x")) {
      newXLog = true;
      newYLog = false;
    } else if (logType.equals("y")) {
      newXLog = false;
      newYLog = true;
    } else if (logType.equals("")) {
      newXLog = false;
      newYLog = false;
    }

    // Do something only if the scale changed
    if (newXLog != xLog || newYLog != yLog) {
      // Set the new log scales
      xLog = newXLog;
      yLog = newYLog;

      // Unfix the limits if the old ones don't make sense
      if (xLog && fixedXLim && (xLim[0] <= 0 || xLim[1] <= 0)) {
        fixedXLim = false;
      }

      if (yLog && fixedYLim && (yLim[0] <= 0 || yLim[1] <= 0)) {
        fixedYLim = false;
      }

      // Calculate the new limits if needed
      if (!fixedXLim) {
        xLim = calculatePlotXLim();
      }

      if (!fixedYLim) {
        yLim = calculatePlotYLim();
      }

      // Update the axes
      xAxis.setLimAndLog(xLim, xLog);
      topAxis.setLimAndLog(xLim, xLog);
      yAxis.setLimAndLog(yLim, yLog);
      rightAxis.setLimAndLog(yLim, yLog);

      // Update the layers
      mainLayer.setLimAndLog(xLim, yLim, xLog, yLog);

      for (int i = 0; i < layerList.size(); i++) {
        layerList.get(i).setLimAndLog(xLim, yLim, xLog, yLog);
      }
    }
  }

  /**
   * Sets if the scale of the horizontal axes should be inverted or not
   *
   * @param newInvertedXScale true if the horizontal scale should be inverted
   */
  public void setInvertedXScale(boolean newInvertedXScale) {
    if (newInvertedXScale != invertedXScale) {
      invertedXScale = newInvertedXScale;
      float temp = xLim[0];
      xLim[0] = xLim[1];
      xLim[1] = temp;

      // Update the axes
      xAxis.setLim(xLim);
      topAxis.setLim(xLim);

      // Update the layers
      mainLayer.setXLim(xLim);

      for (int i = 0; i < layerList.size(); i++) {
        layerList.get(i).setXLim(xLim);
      }
    }
  }

  /**
   * Inverts the horizontal axes scale
   */
  public void invertXScale() {
    setInvertedXScale(!invertedXScale);
  }

  /**
   * Sets if the scale of the vertical axes should be inverted or not
   *
   * @param newInvertedYScale true if the vertical scale should be inverted
   */
  public void setInvertedYScale(boolean newInvertedYScale) {
    if (newInvertedYScale != invertedYScale) {
      invertedYScale = newInvertedYScale;
      float temp = yLim[0];
      yLim[0] = yLim[1];
      yLim[1] = temp;

      // Update the axes
      yAxis.setLim(yLim);
      rightAxis.setLim(yLim);

      // Update the layers
      mainLayer.setYLim(yLim);

      for (int i = 0; i < layerList.size(); i++) {
        layerList.get(i).setYLim(yLim);
      }
    }
  }

  /**
   * Inverts the vertical axes scale
   */
  public void invertYScale() {
    setInvertedYScale(!invertedYScale);
  }

  /**
   * Sets if all the plot layers should be considered in the axes limits calculation
   *
   * @param includeAllLayers true if all layers should be considered and not only the main layer
   */
  public void setIncludeAllLayersInLim(boolean includeAllLayers) {
    if (includeAllLayers != includeAllLayersInLim) {
      includeAllLayersInLim = includeAllLayers;

      // Update the plot limits
      updateLimits();
    }
  }

  /**
   * Sets the factor that is used to expand the axes limits
   *
   * @param expandFactor the new expansion factor
   */
  public void setExpandLimFactor(float expandFactor) {
    if (expandFactor >= 0 && expandFactor != expandLimFactor) {
      expandLimFactor = expandFactor;

      // Update the plot limits
      updateLimits();
    }
  }

  /**
   * Sets the plot background color
   *
   * @param newBgColor the new plot background color
   */
  public void setBgColor(int newBgColor) {
    bgColor = newBgColor;
  }

  /**
   * Sets the box background color
   *
   * @param newBoxBgColor the new box background color
   */
  public void setBoxBgColor(int newBoxBgColor) {
    boxBgColor = newBoxBgColor;
  }

  /**
   * Sets the box line color
   *
   * @param newBoxLineColor the new box background color
   */
  public void setBoxLineColor(int newBoxLineColor) {
    boxLineColor = newBoxLineColor;
  }

  /**
   * Sets the box line width
   *
   * @param newBoxLineWidth the new box line width
   */
  public void setBoxLineWidth(float newBoxLineWidth) {
    if (newBoxLineWidth > 0) {
      boxLineWidth = newBoxLineWidth;
    }
  }

  /**
   * Sets the grid line color
   *
   * @param newGridLineColor the new grid line color
   */
  public void setGridLineColor(int newGridLineColor) {
    gridLineColor = newGridLineColor;
  }

  /**
   * Sets the grid line width
   *
   * @param newGridLineWidth the new grid line width
   */
  public void setGridLineWidth(float newGridLineWidth) {
    if (newGridLineWidth > 0) {
      gridLineWidth = newGridLineWidth;
    }
  }

  /**
   * Sets the points for the main layer
   *
   * @param points the new points for the main layer
   */
  public void setPoints(GPointsArray points) {
    mainLayer.setPoints(points);
    updateLimits();
  }

  /**
   * Sets the points for the specified layer
   *
   * @param points the new points for the main layer
   * @param layerId the layer id
   */
  public void setPoints(GPointsArray points, String layerId) {
    getLayer(layerId).setPoints(points);
    updateLimits();
  }

  /**
   * Sets one of the main layer points
   *
   * @param index the point position
   * @param x the point new x coordinate
   * @param y the point new y coordinate
   * @param label the point new label
   */
  public void setPoint(int index, float x, float y, String label) {
    mainLayer.setPoint(index, x, y, label);
    updateLimits();
  }

  /**
   * Sets one of the specified layer points
   *
   * @param index the point position
   * @param x the point new x coordinate
   * @param y the point new y coordinate
   * @param label the point new label
   * @param layerId the layer id
   */
  public void setPoint(int index, float x, float y, String label, String layerId) {
    getLayer(layerId).setPoint(index, x, y, label);
    updateLimits();
  }

  /**
   * Sets one of the main layer points
   *
   * @param index the point position
   * @param x the point new x coordinate
   * @param y the point new y coordinate
   */
  public void setPoint(int index, float x, float y) {
    mainLayer.setPoint(index, x, y);
    updateLimits();
  }

  /**
   * Sets one of the main layer points
   *
   * @param index the point position
   * @param newPoint the new point
   */
  public void setPoint(int index, GPoint newPoint) {
    mainLayer.setPoint(index, newPoint);
    updateLimits();
  }

  /**
   * Sets one of the specified layer points
   *
   * @param index the point position
   * @param newPoint the new point
   * @param layerId the layer id
   */
  public void setPoint(int index, GPoint newPoint, String layerId) {
    getLayer(layerId).setPoint(index, newPoint);
    updateLimits();
  }

  /**
   * Adds a new point to the main layer points
   *
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   * @param label the new point label
   */
  public void addPoint(float x, float y, String label) {
    mainLayer.addPoint(x, y, label);
    updateLimits();
  }

  /**
   * Adds a new point to the specified layer points
   *
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   * @param label the new point label
   * @param layerId the layer id
   */
  public void addPoint(float x, float y, String label, String layerId) {
    getLayer(layerId).addPoint(x, y, label);
    updateLimits();
  }

  /**
   * Adds a new point to the main layer points
   *
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   */
  public void addPoint(float x, float y) {
    mainLayer.addPoint(x, y);
    updateLimits();
  }

  /**
   * Adds a new point to the main layer points
   *
   * @param newPoint the point to add
   */
  public void addPoint(GPoint newPoint) {
    mainLayer.addPoint(newPoint);
    updateLimits();
  }

  /**
   * Adds a new point to the specified layer points
   *
   * @param newPoint the point to add
   * @param layerId the layer id
   */
  public void addPoint(GPoint newPoint, String layerId) {
    getLayer(layerId).addPoint(newPoint);
    updateLimits();
  }

  /**
   * Adds a new point to the main layer points
   *
   * @param index the position to add the point
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   * @param label the new point label
   */
  public void addPoint(int index, float x, float y, String label) {
    mainLayer.addPoint(index, x, y, label);
    updateLimits();
  }

  /**
   * Adds a new point to the specified layer points
   *
   * @param index the position to add the point
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   * @param label the new point label
   * @param layerId the layer id
   */
  public void addPoint(int index, float x, float y, String label, String layerId) {
    getLayer(layerId).addPoint(index, x, y, label);
    updateLimits();
  }

  /**
   * Adds a new point to the main layer points
   *
   * @param index the position to add the point
   * @param x the new point x coordinate
   * @param y the new point y coordinate
   */
  public void addPoint(int index, float x, float y) {
    mainLayer.addPoint(index, x, y);
    updateLimits();
  }

  /**
   * Adds a new point to the main layer points
   *
   * @param index the position to add the point
   * @param newPoint the point to add
   */
  public void addPoint(int index, GPoint newPoint) {
    mainLayer.addPoint(index, newPoint);
    updateLimits();
  }

  /**
   * Adds a new point to the specified layer points
   *
   * @param index the position to add the point
   * @param newPoint the point to add
   * @param layerId the layer id
   */
  public void addPoint(int index, GPoint newPoint, String layerId) {
    getLayer(layerId).addPoint(index, newPoint);
    updateLimits();
  }

  /**
   * Adds new points to the main layer points
   *
   * @param newPoints the points to add
   */
  public void addPoints(GPointsArray newPoints) {
    mainLayer.addPoints(newPoints);
    updateLimits();
  }

  /**
   * Adds new points to the specified layer points
   *
   * @param newPoints the points to add
   * @param layerId the layer id
   */
  public void addPoints(GPointsArray newPoints, String layerId) {
    getLayer(layerId).addPoints(newPoints);
    updateLimits();
  }

  /**
   * Removes one of the main layer points
   *
   * @param index the point position
   */
  public void removePoint(int index) {
    mainLayer.removePoint(index);
    updateLimits();
  }

  /**
   * Removes one of the specified layer points
   *
   * @param index the point position
   * @param layerId the layer id
   */
  public void removePoint(int index, String layerId) {
    getLayer(layerId).removePoint(index);
    updateLimits();
  }

  /**
   * Sets the point colors for the main layer
   *
   * @param pointColors the point colors for the main layer
   */
  public void setPointColors(int[] pointColors) {
    mainLayer.setPointColors(pointColors);
  }

  /**
   * Sets the point color for the main layer
   *
   * @param pointColor the point color for the main layer
   */
  public void setPointColor(int pointColor) {
    mainLayer.setPointColor(pointColor);
  }

  /**
   * Sets the point sizes for the main layer
   *
   * @param pointSizes the point sizes for the main layer
   */
  public void setPointSizes(float[] pointSizes) {
    mainLayer.setPointSizes(pointSizes);
  }

  /**
   * Sets the point size for the main layer
   *
   * @param pointSize the point sizes for the main layer
   */
  public void setPointSize(float pointSize) {
    mainLayer.setPointSize(pointSize);
  }

  /**
   * Sets the line color for the main layer
   *
   * @param lineColor the line color for the main layer
   */
  public void setLineColor(int lineColor) {
    mainLayer.setLineColor(lineColor);
  }

  /**
   * Sets the line width for the main layer
   *
   * @param lineWidth the line with for the main layer
   */
  public void setLineWidth(float lineWidth) {
    mainLayer.setLineWidth(lineWidth);
  }

  /**
   * Sets the base point for the histogram in the main layer
   *
   * @param basePoint the base point for the histogram in the main layer
   */
  public void setHistBasePoint(GPoint basePoint) {
    mainLayer.setHistBasePoint(basePoint);
  }

  /**
   * Sets the histogram type for the histogram in the main layer
   *
   * @param histType the histogram type for the histogram in the main layer. It can be GPlot.HORIZONTAL or
   *            GPlot.VERTICAL
   */
  public void setHistType(int histType) {
    mainLayer.setHistType(histType);
  }

  /**
   * Sets if the histogram in the main layer is visible or not
   *
   * @param visible if true, the histogram is visible
   */
  public void setHistVisible(boolean visible) {
    mainLayer.setHistVisible(visible);
  }

  /**
   * Sets if the labels of the histogram in the main layer will be drawn or not
   *
   * @param drawHistLabels if true, the histogram labels will be drawn
   */
  public void setDrawHistLabels(boolean drawHistLabels) {
    mainLayer.setDrawHistLabels(drawHistLabels);
  }

  /**
   * Sets the label background color of the points in the main layer
   *
   * @param labelBgColor the label background color of the points in the main layer
   */
  public void setLabelBgColor(int labelBgColor) {
    mainLayer.setLabelBgColor(labelBgColor);
  }

  /**
   * Sets the label separation of the points in the main layer
   *
   * @param labelSeparation the label separation of the points in the main layer
   */
  public void setLabelSeparation(float[] labelSeparation) {
    mainLayer.setLabelSeparation(labelSeparation);
  }

  /**
   * Set the plot title text
   *
   * @param text the plot title text
   */
  public void setTitleText(String text) {
    title.setText(text);
  }

  /**
   * Sets the axis offset for all the axes in the plot
   *
   * @param offset the new axis offset
   */
  public void setAxesOffset(float offset) {
    xAxis.setOffset(offset);
    topAxis.setOffset(offset);
    yAxis.setOffset(offset);
    rightAxis.setOffset(offset);
  }

  /**
   * Sets the tick length for all the axes in the plot
   *
   * @param tickLength the new tick length
   */
  public void setTicksLength(float tickLength) {
    xAxis.setTickLength(tickLength);
    topAxis.setTickLength(tickLength);
    yAxis.setTickLength(tickLength);
    rightAxis.setTickLength(tickLength);
  }

  /**
   * Sets the approximate number of ticks in the horizontal axes. The actual number of ticks depends on the axes
   * limits and the axes scale
   *
   * @param nTicks the new approximate number of ticks in the horizontal axes
   */
  public void setHorizontalAxesNTicks(int nTicks) {
    xAxis.setNTicks(nTicks);
    topAxis.setNTicks(nTicks);
  }

  /**
   * Sets the separation between the ticks in the horizontal axes
   *
   * @param ticksSeparation the new ticks separation in the horizontal axes
   */
  public void setHorizontalAxesTicksSeparation(float ticksSeparation) {
    xAxis.setTicksSeparation(ticksSeparation);
    topAxis.setTicksSeparation(ticksSeparation);
  }

  /**
   * Sets the horizontal axes ticks
   *
   * @param ticks the new horizontal axes ticks
   */
  public void setHorizontalAxesTicks(float[] ticks) {
    xAxis.setTicks(ticks);
    topAxis.setTicks(ticks);
  }

  /**
   * Sets the approximate number of ticks in the vertical axes. The actual number of ticks depends on the axes limits
   * and the axes scale
   *
   * @param nTicks the new approximate number of ticks in the vertical axes
   */
  public void setVerticalAxesNTicks(int nTicks) {
    yAxis.setNTicks(nTicks);
    rightAxis.setNTicks(nTicks);
  }

  /**
   * Sets the separation between the ticks in the vertical axes
   *
   * @param ticksSeparation the new ticks separation in the vertical axes
   */
  public void setVerticalAxesTicksSeparation(float ticksSeparation) {
    yAxis.setTicksSeparation(ticksSeparation);
    rightAxis.setTicksSeparation(ticksSeparation);
  }

  /**
   * Sets the vertical axes ticks
   *
   * @param ticks the new vertical axes ticks
   */
  public void setVerticalAxesTicks(float[] ticks) {
    yAxis.setTicks(ticks);
    rightAxis.setTicks(ticks);
  }

  /**
   * Sets the name of the font that is used in the main layer
   *
   * @param fontName the name of the font that will be used in the main layer
   */
  public void setFontName(String fontName) {
    mainLayer.setFontName(fontName);
  }

  /**
   * Sets the color of the font that is used in the main layer
   *
   * @param fontColor the color of the font that will be used in the main layer
   */
  public void setFontColor(int fontColor) {
    mainLayer.setFontColor(fontColor);
  }

  /**
   * Sets the size of the font that is used in the main layer
   *
   * @param fontSize the size of the font that will be used in the main layer
   */
  public void setFontSize(int fontSize) {
    mainLayer.setFontSize(fontSize);
  }

  /**
   * Sets the properties of the font that is used in the main layer
   *
   * @param fontName the name of the font that will be used in the main layer
   * @param fontColor the color of the font that will be used in the main layer
   * @param fontSize the size of the font that will be used in the main layer
   */
  public void setFontProperties(String fontName, int fontColor, int fontSize) {
    mainLayer.setFontProperties(fontName, fontColor, fontSize);
  }

  /**
   * Sets the properties of the font that will be used in all plot elements (layer, axes, title, histogram)
   *
   * @param fontName the name of the font that will be used in all plot elements
   * @param fontColor the color of the font that will be used in all plot elements
   * @param fontSize the size of the font that will be used in all plot elements
   */
  public void setAllFontProperties(String fontName, int fontColor, int fontSize) {
    xAxis.setAllFontProperties(fontName, fontColor, fontSize);
    topAxis.setAllFontProperties(fontName, fontColor, fontSize);
    yAxis.setAllFontProperties(fontName, fontColor, fontSize);
    rightAxis.setAllFontProperties(fontName, fontColor, fontSize);
    title.setFontProperties(fontName, fontColor, fontSize);

    mainLayer.setAllFontProperties(fontName, fontColor, fontSize);

    for (int i = 0; i < layerList.size(); i++) {
      layerList.get(i).setAllFontProperties(fontName, fontColor, fontSize);
    }
  }

  /**
   * Returns the plot position
   *
   * @return the plot position
   */
  public float[] getPos() {
    return pos.clone();
  }

  /**
   * Returns the plot outer dimensions
   *
   * @return the plot outer dimensions
   */
  public float[] getOuterDim() {
    return outerDim.clone();
  }

  /**
   * Returns the plot margins
   *
   * @return the plot margins
   */
  public float[] getMar() {
    return mar.clone();
  }

  /**
   * Returns the box dimensions
   *
   * @return the box dimensions
   */
  public float[] getDim() {
    return dim.clone();
  }

  /**
   * Returns the limits of the horizontal axes
   *
   * @return the limits of the horizontal axes
   */
  public float[] getXLim() {
    return xLim.clone();
  }

  /**
   * Returns the limits of the vertical axes
   *
   * @return the limits of the vertical axes
   */
  public float[] getYLim() {
    return yLim.clone();
  }

  /**
   * Returns true if the horizontal axes limits are fixed
   *
   * @return true, if the horizontal axes limits are fixed
   */
  public boolean getFixedXLim() {
    return fixedXLim;
  }

  /**
   * Returns true if the vertical axes limits are fixed
   *
   * @return true, if the vertical axes limits are fixed
   */
  public boolean getFixedYLim() {
    return fixedYLim;
  }

  /**
   * Returns true if the horizontal axes scale is logarithmic
   *
   * @return true, if the horizontal axes scale is logarithmic
   */
  public boolean getXLog() {
    return xLog;
  }

  /**
   * Returns true if the vertical axes scale is logarithmic
   *
   * @return true, if the vertical axes scale is logarithmic
   */
  public boolean getYLog() {
    return yLog;
  }

  /**
   * Returns true if the horizontal axes limits are inverted
   *
   * @return true, if the horizontal axes limits are inverted
   */
  public boolean getInvertedXScale() {
    return invertedXScale;
  }

  /**
   * Returns true if the vertical axes limits are inverted
   *
   * @return true, if the vertical axes limits are inverted
   */
  public boolean getInvertedYScale() {
    return invertedYScale;
  }

  /**
   * Returns the plot main layer
   *
   * @return the plot main layer
   */
  public GLayer getMainLayer() {
    return mainLayer;
  }

  /**
   * Returns a layer with an specific id
   *
   * @param id the id of the layer to return
   *
   * @return the layer with the specified id
   */
  public GLayer getLayer(String id) {
    GLayer l = null;

    if (mainLayer.isId(id)) {
      l = mainLayer;
    } else {
      for (int i = 0; i < layerList.size(); i++) {
        if (layerList.get(i).isId(id)) {
          l = layerList.get(i);
          break;
        }
      }
    }

    if (l == null) {
      PApplet.println("Couldn't find a layer in the plot with id = " + id);
    }

    return l;
  }

  /**
   * Returns the plot x axis
   *
   * @return the plot x axis
   */
  public GAxis getXAxis() {
    return xAxis;
  }

  /**
   * Returns the plot top axis
   *
   * @return the plot top axis
   */
  public GAxis getTopAxis() {
    return topAxis;
  }

  /**
   * Returns the plot y axis
   *
   * @return the plot y axis
   */
  public GAxis getYAxis() {
    return yAxis;
  }

  /**
   * Returns the plot right axis
   *
   * @return the plot right axis
   */
  public GAxis getRightAxis() {
    return rightAxis;
  }

  /**
   * Returns the plot title
   *
   * @return the plot title
   */
  public GTitle getTitle() {
    return title;
  }

  /**
   * Returns a copy of the points of the main layer
   *
   * @return a copy of the points of the main layer
   */
  public GPointsArray getPoints() {
    return mainLayer.getPoints();
  }

  /**
   * Returns a copy of the points of the specified layer
   *
   * @param layerId the layer id
   *
   * @return a copy of the points of the specified layer
   */
  public GPointsArray getPoints(String layerId) {
    return getLayer(layerId).getPoints();
  }

  /**
   * Returns the points of the main layer
   *
   * @return the points of the main layer
   */
  public GPointsArray getPointsRef() {
    return mainLayer.getPointsRef();
  }

  /**
   * Returns the points of the specified layer
   *
   * @param layerId the layer id
   *
   * @return the points of the specified layer
   */
  public GPointsArray getPointsRef(String layerId) {
    return getLayer(layerId).getPointsRef();
  }

  /**
   * Returns the histogram of the main layer
   *
   * @return the histogram of the main layer
   */
  public GHistogram getHistogram() {
    return mainLayer.getHistogram();
  }

  /**
   * Returns the histogram of the specified layer
   *
   * @param layerId the layer id
   *
   * @return the histogram of the specified layer
   */
  public GHistogram getHistogram(String layerId) {
    return getLayer(layerId).getHistogram();
  }

  /**
   * Activates the option to zoom with the mouse using the specified buttons and the specified key modifiers
   *
   * @param factor the zoom factor to increase or decrease with each mouse click
   * @param increaseButton the mouse button to increase the zoom. It could be LEFT, RIGHT or CENTER. Select CENTER to
   *            use the mouse wheel
   * @param decreaseButton the mouse button to decrease the zoom. It could be LEFT, RIGHT or CENTER. Select CENTER to
   *            use the mouse wheel
   * @param increaseKeyModifier the key modifier to use in conjunction with the increase zoom mouse button. It could
   *            be GPlot.SHIFTMOD, GPlot.CTRLMOD, GPlot.METAMOD, GPlot.ALTMOD, or GPlot.NONE if no key is needed
   * @param decreaseKeyModifier the key modifier to use in conjunction with the decrease zoom mouse button. It could
   *            be GPlot.SHIFTMOD, GPlot.CTRLMOD, GPlot.METAMOD, GPlot.ALTMOD, or GPlot.NONE if no key is needed
   */
  public void activateZooming(float factor, int increaseButton, int decreaseButton, int increaseKeyModifier,
    int decreaseKeyModifier) {
    zoomingIsActive = true;

    if (factor > 0) {
      zoomFactor = factor;
    }

    if (increaseButton == LEFT || increaseButton == RIGHT || increaseButton == CENTER) {
      increaseZoomButton = increaseButton;
    }

    if (decreaseButton == LEFT || decreaseButton == RIGHT || decreaseButton == CENTER) {
      decreaseZoomButton = decreaseButton;
    }

    if (increaseKeyModifier == SHIFTMOD || increaseKeyModifier == CTRLMOD || increaseKeyModifier == METAMOD
      || increaseKeyModifier == ALTMOD || increaseKeyModifier == NONE) {
      increaseZoomKeyModifier = increaseKeyModifier;
    }

    if (decreaseKeyModifier == SHIFTMOD || decreaseKeyModifier == CTRLMOD || decreaseKeyModifier == METAMOD
      || decreaseKeyModifier == ALTMOD || decreaseKeyModifier == NONE) {
      decreaseZoomKeyModifier = decreaseKeyModifier;
    }
  }

  /**
   * Activates the option to zoom with the mouse using the specified buttons
   *
   * @param factor the zoom factor to increase or decrease with each mouse click
   * @param increaseButton the mouse button to increase the zoom. It could be LEFT, RIGHT or CENTER. Select CENTER to
   *            use the mouse wheel
   * @param decreaseButton the mouse button to decrease the zoom. It could be LEFT, RIGHT or CENTER. Select CENTER to
   *            use the mouse wheel
   */
  public void activateZooming(float factor, int increaseButton, int decreaseButton) {
    activateZooming(factor, increaseButton, decreaseButton, NONE, NONE);
  }

  /**
   * Activates the option to zoom with the mouse using the LEFT and RIGHT buttons
   *
   * @param factor the zoom factor to increase or decrease with each mouse click
   */
  public void activateZooming(float factor) {
    activateZooming(factor, LEFT, RIGHT, NONE, NONE);
  }

  /**
   * Activates the option to zoom with the mouse using the LEFT and RIGHT buttons
   */
  public void activateZooming() {
    activateZooming(1.3f, LEFT, RIGHT, NONE, NONE);
  }

  /**
   * Deactivates the option to zoom with the mouse
   */
  public void deactivateZooming() {
    zoomingIsActive = false;
  }

  /**
   * Activates the option to center the plot with the mouse using the specified button and the specified key modifier
   *
   * @param button the mouse button to use. It could be LEFT, RIGHT or CENTER. Select CENTER to use the mouse wheel
   * @param keyModifier the key modifier to use in conjunction with the mouse button. It could be GPlot.SHIFTMOD,
   *            GPlot.CTRLMOD, GPlot.METAMOD, GPlot.ALTMOD, or GPlot.NONE if no key is need
   */
  public void activateCentering(int button, int keyModifier) {
    centeringIsActive = true;

    if (button == LEFT || button == RIGHT || button == CENTER) {
      centeringButton = button;
    }

    if (keyModifier == SHIFTMOD || keyModifier == CTRLMOD || keyModifier == METAMOD || keyModifier == ALTMOD
      || keyModifier == NONE) {
      centeringKeyModifier = keyModifier;
    }
  }

  /**
   * Activates the option to center the plot with the mouse using the specified button
   *
   * @param button the mouse button to use. It could be LEFT, RIGHT or CENTER. Select CENTER to use the mouse wheel
   */
  public void activateCentering(int button) {
    activateCentering(button, NONE);
  }

  /**
   * Activates the option to center the plot with the mouse using the LEFT button
   */
  public void activateCentering() {
    activateCentering(LEFT, NONE);
  }

  /**
   * Deactivates the option to center the plot with the mouse
   */
  public void deactivateCentering() {
    centeringIsActive = false;
  }

  /**
   * Activates the option to pan the plot with the mouse using the specified button and the specified key modifier
   *
   * @param button the mouse button to use. It could be LEFT, RIGHT or CENTER
   * @param keyModifier the key modifier to use in conjunction with the mouse button. It could be GPlot.SHIFTMOD,
   *            GPlot.CTRLMOD, GPlot.METAMOD, GPlot.ALTMOD, or GPlot.NONE if no key is need
   */
  public void activatePanning(int button, int keyModifier) {
    panningIsActive = true;

    if (button == LEFT || button == RIGHT || button == CENTER) {
      panningButton = button;
    }

    if (keyModifier == SHIFTMOD || keyModifier == CTRLMOD || keyModifier == METAMOD || keyModifier == ALTMOD
      || keyModifier == NONE) {
      panningKeyModifier = keyModifier;
    }
  }

  /**
   * Activates the option to pan the plot with the mouse using the specified button
   *
   * @param button the mouse button to use. It could be LEFT, RIGHT or CENTER
   */
  public void activatePanning(int button) {
    activatePanning(button, NONE);
  }

  /**
   * Activates the option to pan the plot with the mouse using the LEFT button
   */
  public void activatePanning() {
    activatePanning(LEFT, NONE);
  }

  /**
   * Deactivates the option to pan the plot with the mouse
   */
  public void deactivatePanning() {
    panningIsActive = false;
    panningReferencePoint = null;
  }

  /**
   * Activates the option to draw the labels of the points with the mouse using the specified button and the specified
   * key modifier
   *
   * @param button the mouse button to use. It could be LEFT, RIGHT or CENTER
   * @param keyModifier the key modifier to use in conjunction with the mouse button. It could be GPlot.SHIFTMOD,
   *            GPlot.CTRLMOD, GPlot.METAMOD, GPlot.ALTMOD, or GPlot.NONE if no key is need
   */
  public void activatePointLabels(int button, int keyModifier) {
    labelingIsActive = true;

    if (button == LEFT || button == RIGHT || button == CENTER) {
      labelingButton = button;
    }

    if (keyModifier == SHIFTMOD || keyModifier == CTRLMOD || keyModifier == METAMOD || keyModifier == ALTMOD
      || keyModifier == NONE) {
      labelingKeyModifier = keyModifier;
    }
  }

  /**
   * Activates the option to draw the labels of the points with the mouse using the specified button
   *
   * @param button the mouse button to use. It could be LEFT, RIGHT or CENTER
   */
  public void activatePointLabels(int button) {
    activatePointLabels(button, NONE);
  }

  /**
   * Activates the option to draw the labels of the points with the mouse using the LEFT button
   */
  public void activatePointLabels() {
    activatePointLabels(LEFT, NONE);
  }

  /**
   * Deactivates the option to draw the labels of the points with the mouse
   */
  public void deactivatePointLabels() {
    labelingIsActive = false;
    mousePos = null;
  }

  /**
   * Activates the option to return to the value of the axes limits previous to any mouse interaction, using the
   * specified button and the specified key modifier
   *
   * @param button the mouse button to use. It could be LEFT, RIGHT or CENTER. Select CENTER to use the mouse wheel
   * @param keyModifier the key modifier to use in conjunction with the mouse button. It could be GPlot.SHIFTMOD,
   *            GPlot.CTRLMOD, GPlot.METAMOD, GPlot.ALTMOD, or GPlot.NONE if no key is need
   */
  public void activateReset(int button, int keyModifier) {
    resetIsActive = true;
    xLimReset = null;
    yLimReset = null;

    if (button == LEFT || button == RIGHT || button == CENTER) {
      resetButton = button;
    }

    if (keyModifier == SHIFTMOD || keyModifier == CTRLMOD || keyModifier == METAMOD || keyModifier == ALTMOD
      || keyModifier == NONE) {
      resetKeyModifier = keyModifier;
    }
  }

  /**
   * Activates the option to return to the value of the axes limits previous to any mouse interaction, using the
   * specified button
   *
   * @param button the mouse button to use. It could be LEFT, RIGHT or CENTER. Select CENTER to use the mouse wheel
   */
  public void activateReset(int button) {
    activateReset(button, NONE);
  }

  /**
   * Activates the option to return to the value of the axes limits previous to any mouse interaction, using the RIGHT
   * button
   */
  public void activateReset() {
    activateReset(RIGHT, NONE);
  }

  /**
   * Deactivates the option to return to the value of the axes limits previous to any mouse interaction using the
   * mouse
   */
  public void deactivateReset() {
    resetIsActive = false;
    xLimReset = null;
    yLimReset = null;
  }

  /**
   * Mouse events (zooming, centering, panning, labeling)
   *
   * @param event the mouse event detected by the processing applet
   */
  public void mouseEvent(MouseEvent event) {
    if (zoomingIsActive || centeringIsActive || panningIsActive || labelingIsActive || resetIsActive) {
      int action = event.getAction();
      int button = (action == MouseEvent.WHEEL) ? CENTER : event.getButton();
      int modifiers = event.getModifiers();
      float xMouse = event.getX();
      float yMouse = event.getY();
      int wheelCounter = (action == MouseEvent.WHEEL) ? event.getCount() : 0;

      if (zoomingIsActive && (action == MouseEvent.CLICK || action == MouseEvent.WHEEL)) {
        if (button == increaseZoomButton
          && (increaseZoomKeyModifier == NONE || (modifiers & increaseZoomKeyModifier) != 0)) {
          if (isOverBox(xMouse, yMouse)) {
            // Save the axes limits if it's the first mouse
            // modification after the last reset
            if (resetIsActive && (xLimReset == null || yLimReset == null)) {
              xLimReset = xLim.clone();
              yLimReset = yLim.clone();
            }

            if (wheelCounter <= 0) {
              zoom(zoomFactor, xMouse, yMouse);
            }
          }
        }

        if (button == decreaseZoomButton
          && (decreaseZoomKeyModifier == NONE || (modifiers & decreaseZoomKeyModifier) != 0)) {
          if (isOverBox(xMouse, yMouse)) {
            // Save the axes limits if it's the first mouse
            // modification after the last reset
            if (resetIsActive && (xLimReset == null || yLimReset == null)) {
              xLimReset = xLim.clone();
              yLimReset = yLim.clone();
            }

            if (wheelCounter >= 0) {
              zoom(1 / zoomFactor, xMouse, yMouse);
            }
          }
        }
      }

      if (centeringIsActive && (action == MouseEvent.CLICK || action == MouseEvent.WHEEL)) {
        if (button == centeringButton
          && (centeringKeyModifier == NONE || (modifiers & centeringKeyModifier) != 0)) {
          if (isOverBox(xMouse, yMouse)) {
            // Save the axes limits if it's the first mouse
            // modification after the last reset
            if (resetIsActive && (xLimReset == null || yLimReset == null)) {
              xLimReset = xLim.clone();
              yLimReset = yLim.clone();
            }

            center(xMouse, yMouse);
          }
        }
      }

      if (panningIsActive) {
        if (button == panningButton && (panningKeyModifier == NONE || (modifiers & panningKeyModifier) != 0)) {
          if (action == MouseEvent.DRAG) {
            if (panningReferencePoint != null) {
              // Save the axes limits if it's the first mouse
              // modification after the last reset
              if (resetIsActive && (xLimReset == null || yLimReset == null)) {
                xLimReset = xLim.clone();
                yLimReset = yLim.clone();
              }

              align(panningReferencePoint, xMouse, yMouse);
            } else if (isOverBox(xMouse, yMouse)) {
              panningReferencePoint = getValueAt(xMouse, yMouse);
            }
          } else if (action == MouseEvent.RELEASE) {
            panningReferencePoint = null;
          }
        }
      }

      if (labelingIsActive) {
        if (button == labelingButton
          && (labelingKeyModifier == NONE || (modifiers & labelingKeyModifier) != 0)) {
          if ((action == MouseEvent.PRESS || action == MouseEvent.DRAG) && isOverBox(xMouse, yMouse)) {
            mousePos = new float[] { xMouse, yMouse };
          } else {
            mousePos = null;
          }
        }
      }

      if (resetIsActive && (action == MouseEvent.CLICK || action == MouseEvent.WHEEL)) {
        if (button == resetButton && (resetKeyModifier == NONE || (modifiers & resetKeyModifier) != 0)) {
          if (isOverBox(xMouse, yMouse)) {
            if (xLimReset != null && yLimReset != null) {
              setXLim(xLimReset);
              setYLim(yLimReset);
              xLimReset = null;
              yLimReset = null;
            }
          }
        }
      }
    }
  }
}

// GPlotD --> GPlotE 2022.12.08. Hegyesi mod: overload addLayer

//import grafica.GPlot;
//import grafica.GAxisLabel;
//import grafica.GPointsArray;
//import processing.core.PApplet;
import java.io.PrintWriter;
import java.io.File;
//import processing.event.MouseEvent;
//import processing.event.KeyEvent;

public class GPlotE extends GPlot {

  float [] defaultPos = {5, 5 };
  float [] defaultOuterDim = { parent.width-2*defaultPos[0], parent.height-2*defaultPos[1] };

  //boolean autoscaleIsEnabled = true;
  boolean xZoom = true;
  boolean yZoom = true;
  boolean sKeyIsDown = false;
  //boolean windowHasBeenResized = false;
  //boolean plotIsResizable = true;
  boolean framePanningIsActive = false;
  boolean frameZoomingIsActive = false;
  boolean frameResetIsActive = false;

  // For Histo2D
  int [][] suniMatrix = new int [1][1];
  int fillRange;
  float fillScale = 1;
  int fillRangeIncrDecr;
  int [][] colorMap;
  PGraphics pg;
  PImage img;

  boolean isPressed = false;
  boolean isOnTop = false;

  // Constructors
  GPlotE(PApplet pa, String plotTitle, String xAxisLable, String yAxisLable) {
    // Invocation of a superclass constructor must be the first line in the subclass constructor.
    super(pa);
    // Set plot position and outerDim on the screen
    setPos(defaultPos);
    setOuterDim(defaultOuterDim);
    //init(plotTitle, xAxisLable, yAxisLable);
    parent.registerMethod("keyEvent", this);

    // Set the plot title and the axis labels
    getXAxis().setAxisLabelText(xAxisLable);
    getYAxis().setAxisLabelText(yAxisLable);
    setTitleText(plotTitle);
    // Setup the mouse actions
    activatePanning();
    activateReset();
    activateZooming(1.1f, CENTER, CENTER);
    setBgColor(color(240));
    setBoxBgColor(color(250, 250, 250));
    setBoxLineWidth(2);
    //println("init");
    new MyThread().start();
  }

  GPlotE(PApplet pa, String plotTitle) {
    this(pa, plotTitle, "", "");
  }

  GPlotE(PApplet pa) {
    this(pa, "", "", "");
  }


  // Add Layer methods
  void addLayer(float[] x, float[] y, String id, float lineWidth, float pointSize) {
    boolean sameId = false;

    for (int i = 0; i < layerList.size (); i++) {
      if (layerList.get(i).isId(id)) {
        sameId = true;
        break;
      }
    }
    if (!sameId) {
      GPointsArray pointsArray = new GPointsArray();
      pointsArray.add(x, y);
      addLayer(id, pointsArray);
      getLayer(id).setLineColor(boyntonOptimized[(layerList.size()-1) % boyntonOptimized.length]);
      getLayer(id).setPointColors( new int[] {boyntonOptimized[(layerList.size()-1) % boyntonOptimized.length]} );
      if (pointSize < 0) pointSize = 0;
      getLayer(id).setPointSizes( new float[] { pointSize } );
      if (lineWidth <= 0) lineWidth = (float)0.1;
      getLayer(id).setLineWidth(lineWidth);
    } else {
      PApplet.println("==> A layer with the same id exists. Please change the id and try to add it again.");
    }
    //parent.redraw();
  }


  void addLayer(float[] x, float[] y, String id, float lineWidth) {
    addLayer(x, y, id, lineWidth, 0);
  }


  void addLayer(float[] x, float[] y, String id) {
    addLayer(x, y, id, 2, 0);
  }


  void addLayer(float[] x, float[] y) {
    addLayer(x, y, str(layerList.size()), 2, 0);
  }


  void addLayer(double[] x, double[] y)
  {
    addLayer( doubleToFloat(x), doubleToFloat(y) );
  }


  void addLayer(float[] x, float[] y, boolean hist) {
    addLayer(x, y);
    if (hist) {
      getLayer(str(layerList.size()-1)).startHistogram(GPlot.VERTICAL);
    }
  }


  void addLayer(float[] x, float[] y, float lineWidth, float pointSize) {
    addLayer(x, y, str(layerList.size()), lineWidth, pointSize);
  }


  void addLayer(double[] x, double[] y, float lineWidth, float pointSize)
  {
    addLayer(doubleToFloat(x), doubleToFloat(y), lineWidth, pointSize);
  }


  void addLayer(float[] x, float[] y, float lineWidth) {
    addLayer(x, y, str(layerList.size()), lineWidth, 0);
  }


  void addLayer(float[] y, float lineWidth, float pointSize) {
    float [] x = new float [y.length];
    for (int i=0; i<y.length; i++) x[i] = i;
    addLayer(x, y, str(layerList.size()), lineWidth, pointSize);
  }


  void addLayer(float[] y, float lineWidth) {
    float [] x = new float [y.length];
    for (int i=0; i<y.length; i++) x[i] = i;
    addLayer(x, y, str(layerList.size()), lineWidth, 0);
  }


  void addLayer(float[] y) {
    float [] x = new float [y.length];
    for (int i=0; i<y.length; i++) x[i] = i;
    addLayer(x, y, str(layerList.size()), 2, 0);
  }


  void addLayer(float[] y, boolean hist) {
    addLayer(y);
    if (hist) {
      getLayer(str(layerList.size()-1)).startHistogram(GPlot.VERTICAL);
    }
  }

  // 2022.12.08. Hegyesi mod: overload addLayer
  // prevent too many points to slow down plot
  /**
   * Adds a new layer to the plot
   *
   * @param id the id to use for the new layer
   * @param points the points to be included in the layer
   */
  public void addLayer(String id, GPointsArray points) {
    // Check that it is the only layer with that id
    boolean sameId = false;

    if (mainLayer.isId(id)) {
      sameId = true;
    } else {
      for (int i = 0; i < layerList.size(); i++) {
        if (layerList.get(i).isId(id)) {
          sameId = true;
          break;
        }
      }
    }

    // Add the layer to the list
    if (!sameId) {
      GLayer newLayer = new GLayer(parent, id, dim, xLim, yLim, xLog, yLog);
      // 2022.12.08. Hegyesi mod begin
      //newLayer.setPoints(points);
      GPointsArray pointsThin = new GPointsArray();
      int nPoints = points.getNPoints();
      int step = nPoints / 1000;
      step = max(step, 1);
      if (!fixedXLim) {
        for (int i = 0; i < nPoints; i+=step) {
          pointsThin.add( points.get(i) );
        }
      } else {
        int minIndex = binSearch(points, xLim[0]);
        int maxIndex = binSearch(points, xLim[1]);
        step = (maxIndex - minIndex) / 1000;
        //println("xLim[0]:" + xLim[0]);
        //println("maxIndex:" + maxIndex);
        //println("minIndex:" + minIndex);
        //println(step);
        step = max(step, 1);
        for (int i = minIndex; i < maxIndex; i+=step) {
          pointsThin.add( points.get(i) );
        }
      }
      newLayer.setPoints(pointsThin);
      // 2022.12.08. Hegyesi mod end
      layerList.add(newLayer);

      // Calculate and update the new plot limits if necessary
      if (includeAllLayersInLim) {
        updateLimits();
      }
    } else {
      PApplet.println("A layer with the same id exists. Please change the id and try to add it again.");
    }
  }

  private int binSearch(GPointsArray array, float valueToFind) {
    int pos=0;
    int limit=array.getNPoints();

    while (pos < limit) {
      int testpos = (pos + limit) >> 1;

      if ( array.getX(testpos) < valueToFind )
        pos = testpos + 1;
      else
        limit = testpos;
    }
    return pos;
  }


  void addHisto2D(int [][] suniMatrix, int [][] colorMap) {
    this.colorMap = colorMap;
    fillRange = colorMap.length;
    fillRangeIncrDecr = fillRange/10;
    // Hegyesi mod. start 2022.09.06.
    if ( (this.suniMatrix.length != suniMatrix.length) || (this.suniMatrix[0].length != suniMatrix[0].length) ) {
      pg = createGraphics( suniMatrix.length*1, suniMatrix[0].length*1);
      //println("createGraphics");
    }
    // Hegyesi mod. end 2022.09.06.

    this.suniMatrix = suniMatrix;

    // Hegyesi mod. start 2020.11.23
    //setXLim(0, suniMatrix.length);
    //setYLim(0, suniMatrix[0].length);
    GPointsArray dummyPoints = new GPointsArray();
    dummyPoints.add(0, 0);
    dummyPoints.add(suniMatrix.length, suniMatrix[0].length);
    // Add the points for the 0. layer
    addLayer("0", dummyPoints);
    // Set points' size for the 0. layer
    getLayer("0").setPointSize(0);
    // Hegyesi mod. end 2020.11.23
    getLayer("0").setLineWidth(0.01);

    img = CreatePImageFromMat(suniMatrix);
  }

  // Create PImage from matrix
  PImage CreatePImageFromMat(int [][] suniMatrix) {
    int w = suniMatrix.length;
    int h = suniMatrix[0].length;
    PImage img_ = createImage(w, h, RGB);
    img_.loadPixels();
    int maxVal = maxMat(suniMatrix);

    for (int i = 0; i < w; i++) {
      for (int j = 0; j < h; j++) {
        float fillValue = fillScale * suniMatrix[i][h-1-j] / (float)maxVal * colorMap.length;
        fillValue = constrain(fillValue, 0, colorMap.length-1);
        int fillValueI = int(fillValue);
        img_.pixels[j*w + i] = color( colorMap[fillValueI][0], colorMap[fillValueI][1], colorMap[fillValueI][2] );
      }
    }
    img_.updatePixels();
    return img_;
  }


  // Find maximum of a matrix
  int maxMat(int[][] x) {
    int maxVal = 1;
    for (int[] row : x) {
      maxVal = max( max(row), maxVal );
    }
    return maxVal;
  }

  // Draw method
  void draw() {
    try {
      //// Update outerDim if width or height has changed
      //if (windowHasBeenResized && plotIsResizable) {
      //  outerDim = new float[] { parent.width-2*pos[0], parent.height-2*pos[1] };
      //  setOuterDim(outerDim);
      //  windowHasBeenResized = false;
      //}

      setHorizontalAxesNTicks( round(outerDim[0] /100) );
      setVerticalAxesNTicks( round(outerDim[1] /100) );

      // Draw it!
      beginDraw();
      drawBackground();
      drawBox();
      drawXAxis();
      drawYAxis();
      drawTitle();
      drawGridLines(GPlot.BOTH);

      for (int i = 0; i < layerList.size (); i++) {
        if (layerList.get(i).getHistogram() == null) {
          layerList.get(i).drawLines();
          layerList.get(i).drawPoints();
        } else {
          layerList.get(i).drawHistogram();
        }
      }
      drawLabels();
      endDraw();

      // Plot suniMatrix off-screen
      if (pg != null) {
        pg.beginDraw();
        pg.background(200);
        pg.image(img, 0, 0);
        // Get section of suniMatrix image within plot1 box area
        int x = (int) (getXLim()[0]*1);
        int y =  (int) ((suniMatrix[0].length - getYLim()[1])*1);  // Hegyesi mod. 2022.09.06.
        int w = (int) ((getXLim()[1] - getXLim()[0])*1);
        int h = (int) ((getYLim()[1] - getYLim()[0])*1);
        PImage crop = pg.get( x, y, w, h ); // get() params are not affected by transformations
        pg.endDraw();

        // Get box position and size
        float a = getPos()[0] + getMar()[1];
        float b = getPos()[1] + getMar()[2];
        float c = getDim()[0];
        float d = getDim()[1];
        image(crop, a, b, c, d);
        //println(frameCount + ": image");
      }
    }
    catch (Exception e) {
      println("Exception in GPlotC draw() @ frameCount = " + parent.frameCount + ": " + e);
      //e.printStackTrace();
      endDraw();
    }
  }

  /**
   * Draws the plot background. This includes the box area and the margins
   */
  public void drawBackground() {
    parent.pushStyle();
    parent.rectMode(CORNER);
    parent.strokeWeight(2);
    parent.noFill();
    if (isOnTop) parent.rect(-mar[1]+2, -mar[2] - dim[1]+2, outerDim[0], outerDim[1], 10);
    parent.fill(bgColor);
    parent.rect(-mar[1], -mar[2] - dim[1], outerDim[0], outerDim[1], 10);
    parent.popStyle();
  }


  // Clear method
  void clear() {
    layerList.clear();
  }



  /**
   * Zooms the limits range by a given factor keeping the same plot value at
   * the specified screen position
   *
   * @param factor
   *            the plot limits will be zoomed by this factor
   * @param xScreen
   *            x screen position in the parent Processing applet
   * @param yScreen
   *            y screen position in the parent Processing applet
   */
  public void zoom(float factor, float xScreen, float yScreen) {
    float[] plotPos = getPlotPosAt(xScreen, yScreen);
    float[] value = mainLayer.plotToValue(plotPos[0], plotPos[1]);

    if (xZoom) {
      if (xLog) {
        float deltaLim = PApplet.exp(PApplet.log(xLim[1] / xLim[0]) / (2 * factor));
        float offset = PApplet.exp((PApplet.log(xLim[1] / xLim[0]) / factor) * (0.5f - plotPos[0] / dim[0]));
        xLim = new float[] {
          value[0] * offset / deltaLim, value[0] * offset * deltaLim
        };
      } else {
        float deltaLim = (xLim[1] - xLim[0]) / (2 * factor);
        float offset = 2 * deltaLim * (0.5f - plotPos[0] / dim[0]);
        xLim = new float[] {
          value[0] + offset - deltaLim, value[0] + offset + deltaLim
        };
      }
    }

    if (yZoom) {
      if (yLog) {
        float deltaLim = PApplet.exp(PApplet.log(yLim[1] / yLim[0]) / (2 * factor));
        float offset = PApplet.exp((PApplet.log(yLim[1] / yLim[0]) / factor) * (0.5f + plotPos[1] / dim[1]));
        yLim = new float[] {
          value[1] * offset / deltaLim, value[1] * offset * deltaLim
        };
      } else {
        float deltaLim = (yLim[1] - yLim[0]) / (2 * factor);
        float offset = 2 * deltaLim * (0.5f + plotPos[1] / dim[1]);
        yLim = new float[] {
          value[1] + offset - deltaLim, value[1] + offset + deltaLim
        };
      }
    }

    // Fix the limits
    fixedXLim = true;
    fixedYLim = true;

    // Update the horizontal and vertical axes
    xAxis.setLim(xLim);
    topAxis.setLim(xLim);
    yAxis.setLim(yLim);
    rightAxis.setLim(yLim);

    // Update the plot limits (the layers, because the limits are fixed)
    updateLimits();
  }



  // Color palettes
  // http://stackoverflow.com/questions/470690/how-to-automatically-generate-n-distinct-colors
  // http://jsfiddle.net/k8NC2/1/

  int [] boyntonOptimized = new int []
    {
    color(255, 0, 0), //Red
    color(0, 185, 0), //Green
    color(0, 0, 255), //Blue
    color(255, 128, 0), //Orange
    color(255, 0, 255), //Magenta
    color(255, 128, 128), //Pink
    color(128, 128, 128), //Gray
    color(128, 0, 0), //Brown
    color(255, 255, 0), //Yellow
  };

  int [] kellysMaxContrast = new int []
    {
    (0xFFFFB300), //Vivid Yellow
    (0xFF803E75), //Strong Purple
    (0xFFFF6800), //Vivid Orange
    (0xFFA6BDD7), //Very Light Blue
    (0xFFC10020), //Vivid Red
    (0xFFCEA262), //Grayish Yellow
    (0xFF817066), //Medium Gray

    //The following will not be good for people with defective color vision
    (0xFF007D34), //Vivid Green
    (0xFFF6768E), //Strong Purplish Pink
    (0xFF00538A), //Strong Blue
    (0xFFFF7A5C), //Strong Yellowish Pink
    (0xFF53377A), //Strong Violet
    (0xFFFF8E00), //Vivid Orange Yellow
    (0xFFB32851), //Strong Purplish Red
    (0xFFF4C800), //Vivid Greenish Yellow
    (0xFF7F180D), //Strong Reddish Brown
    (0xFF93AA00), //Vivid Yellowish Green
    (0xFF593315), //Deep Yellowish Brown
    (0xFFF13A13), //Vivid Reddish Orange
    (0xFF232C16), //Dark Olive Green
  };



  public void keyEvent(KeyEvent event) {
    int action = event.getAction();
    int kCode = event.getKeyCode();

    if (action == KeyEvent.PRESS) {
      switch (kCode) {
      case CONTROL:    // Change zoom direction
        yZoom =  false;
        break;
      case 'S':
        sKeyIsDown = true;
        break;
      case SHIFT:
        xZoom =  false;
        break;
      }
    } else if (action == KeyEvent.RELEASE) {
      switch (kCode) {
      case CONTROL:    // Change zoom direction
        yZoom =  true;
        break;
      case 'S':
        sKeyIsDown = false;
        break;
      case SHIFT:
        xZoom =  true;
        break;
      }
    }
    //
  }



  boolean dragStartedOverBox = false;  // Hegyesi mod. 2019.06.06.

  // overwriting the mouseEvent method of GPlot
  public void mouseEvent(MouseEvent event) {
    try {
      int action = event.getAction();
      int button = (action == MouseEvent.WHEEL) ? CENTER : event.getButton();
      int modifiers = event.getModifiers();
      float xMouse = event.getX();
      float yMouse = event.getY();
      int wheelCounter = (action == MouseEvent.WHEEL) ? event.getCount() : 0;

      // begin hegyesi's extension
      boolean isOverSketchWindow =
        (xMouse > 0) &&
        (xMouse < parent.width) &&
        (yMouse > 0) &&
        (yMouse < parent.height);


      switch (action) {
      case MouseEvent.CLICK:
        if (isOverBox(xMouse, yMouse) && button == RIGHT && sKeyIsDown)
          savePlotsToSketchFolder();  // if "s" is pressed + mouse right clicked
        break;
      case MouseEvent.PRESS:
        if (isOverBox(xMouse, yMouse)) {
          dragStartedOverBox = true;
        }
        if (isOverPlot(xMouse, yMouse)) {
          isPressed = true;
        } else isOnTop = false;
        break;
      case MouseEvent.RELEASE:
        dragStartedOverBox = false;
        break;
        //case MouseEvent.MOVE:
        //   println(frameCount + ": " + dragStartedOverBox);
        //   loop();
        //   break;
      }

      if (isOnTop) {
        if ( !isOverBox(xMouse, yMouse) && isOverPlot(xMouse, yMouse)) {

          switch (action) {
          case MouseEvent.DRAG:
            if (!dragStartedOverBox && isOverSketchWindow && framePanningIsActive && button == LEFT) { // drag
              //if ( isOverSketchWindow && framePanningIsActive && button == LEFT) { // drag
              float newPosX = getPos()[0] + xMouse - parent.pmouseX;
              float newPosY = getPos()[1] + yMouse - parent.pmouseY;
              setPos(newPosX, newPosY);
            }
            break;
          case MouseEvent.WHEEL:
            if (frameZoomingIsActive) { // zoom
              float zoom = event.getCount() < 0 ? 1.03 : 1/1.03;
              float newOuterDimX = getOuterDim()[0];
              if (xZoom) newOuterDimX *= zoom;
              float newOuterDimY = getOuterDim()[1];
              if (yZoom) newOuterDimY *= zoom;
              setOuterDim(newOuterDimX, newOuterDimY);
              float posX = getPos()[0];
              float posY = getPos()[1];
              float newPosX = posX;
              if (xZoom) newPosX = xMouse - (xMouse - posX) * zoom;
              float newPosY = posY;
              if (yZoom) newPosY = yMouse - (yMouse - posY) * zoom;
              setPos(newPosX, newPosY);
            }
            break;
          case MouseEvent.CLICK:
            if (frameResetIsActive && button == RIGHT) {
              // Set plot default position and outerDim on the screen
              setPos(defaultPos);
              setOuterDim(defaultOuterDim);
            }
            break;
          }
        }

        //setSurfaceTitle();
        // end hegyesi's extension

        if (zoomingIsActive && (action == MouseEvent.CLICK || action == MouseEvent.WHEEL)) {
          if (button == increaseZoomButton
            && (increaseZoomKeyModifier == NONE || (modifiers & increaseZoomKeyModifier) != 0)) {
            if (isOverBox(xMouse, yMouse)) {
              // Save the axes limits if it's the first mouse
              // modification after the last reset
              if (resetIsActive && (xLimReset == null || yLimReset == null)) {
                xLimReset = xLim.clone();
                yLimReset = yLim.clone();
              }

              if (wheelCounter <= 0) {
                zoom(zoomFactor, xMouse, yMouse);
              }
            }
          }

          if (button == decreaseZoomButton
            && (decreaseZoomKeyModifier == NONE || (modifiers & decreaseZoomKeyModifier) != 0)) {
            if (isOverBox(xMouse, yMouse)) {
              // Save the axes limits if it's the first mouse
              // modification after the last reset
              if (resetIsActive && (xLimReset == null || yLimReset == null)) {
                xLimReset = xLim.clone();
                yLimReset = yLim.clone();
              }

              if (wheelCounter >= 0) {
                zoom(1 / zoomFactor, xMouse, yMouse);
              }
            }
          }
        }

        if (centeringIsActive && (action == MouseEvent.CLICK || action == MouseEvent.WHEEL)) {
          if (button == centeringButton
            && (centeringKeyModifier == NONE || (modifiers & centeringKeyModifier) != 0)) {
            if (isOverBox(xMouse, yMouse)) {
              // Save the axes limits if it's the first mouse
              // modification after the last reset
              if (resetIsActive && (xLimReset == null || yLimReset == null)) {
                xLimReset = xLim.clone();
                yLimReset = yLim.clone();
              }

              center(xMouse, yMouse);
            }
          }
        }

        if (panningIsActive) {
          if (button == panningButton && (panningKeyModifier == NONE || (modifiers & panningKeyModifier) != 0)) {
            if (action == MouseEvent.DRAG) {
              if (panningReferencePoint != null) {
                // Save the axes limits if it's the first mouse
                // modification after the last reset
                if (resetIsActive && (xLimReset == null || yLimReset == null)) {
                  xLimReset = xLim.clone();
                  yLimReset = yLim.clone();
                }

                align(panningReferencePoint, xMouse, yMouse);
                //parent.loop();  // Hegyesi mod. 2019.06.06.
              } else if (isOverBox(xMouse, yMouse)) {
                panningReferencePoint = getValueAt(xMouse, yMouse);
              }
            } else if (action == MouseEvent.RELEASE) {
              panningReferencePoint = null;
            }
          }
        }

        if (labelingIsActive) {
          if (button == labelingButton
            && (labelingKeyModifier == NONE || (modifiers & labelingKeyModifier) != 0)) {
            if ((action == MouseEvent.PRESS || action == MouseEvent.DRAG) && isOverBox(xMouse, yMouse)) {
              mousePos = new float[] { xMouse, yMouse };
            } else {
              mousePos = null;
            }
          }
        }

        if (resetIsActive && (action == MouseEvent.CLICK || action == MouseEvent.WHEEL)) {
          if (button == resetButton && (resetKeyModifier == NONE || (modifiers & resetKeyModifier) != 0)) {
            if (isOverBox(xMouse, yMouse)) {
              if (xLimReset != null && yLimReset != null) {
                // Hegyesi mod. start 2020.11.19
                //setXLim(xLimReset);
                //setYLim(yLimReset);
                //xLimReset = null;
                //yLimReset = null;
                fixedXLim = false;
                fixedYLim = false;
                updateLimits();
                // Hegyesi mod. end 2020.11.19
              }
            }
          }
        }
      }
      if (action != MouseEvent.MOVE) parent.loop();
    }
    catch (Exception e) {
      println("Exception in GPlotC  mouseEvent @ frameCount = " + frameCount + ": " + e);
    }
  }


  void savePlotsToSketchFolder()
  {

    for (int i = 0; i < layerList.size (); i++)
    {
      int nPoints = layerList.get(i).getPoints().getNPoints();
      float [] xLim = getXLim();
      float [] yLim = getYLim();

      String id = layerList.get(i).getId();
      PrintWriter fileOut = parent.createWriter("plot_" + id + ".txt");
      println ("x" + id + "\ty" + id);
      fileOut.println ("x" + id + "\ty" + id);

      for (int j=0; j<nPoints; j++)
      {
        float x = layerList.get(i).getPoints().get(j).getX();
        float y = layerList.get(i).getPoints().get(j).getY();
        if ( x >= xLim[0] && x <= xLim[1] && y >= yLim[0] && y <= yLim[1] )
        {
          println ( x + "\t " + y );
          fileOut.println ( x + "\t\t " + y );
        }
      }
      fileOut.flush();  // Writes the remaining data to the file
      fileOut.close();

      println("Saved to plot_" + id + ".txt");
      println();
    }
  }

  private float [] doubleToFloat(double [] d)
  {
    float f[] = new float[d.length];
    for (int i=0; i<f.length; i++)
      f[i] = (float)(d[i]);
    return f;
  }


  public void windowResized() {
    int pWidth = 0, pHeight = 0;
    while (true) {
      if (pWidth != parent.width || pHeight != parent.height) {
        // Window has been resized so redraw parent
        //parent.redraw();
        //windowHasBeenResized = true;
        parent.loop();
        // save current window size
        pWidth = parent.width;
        pHeight = parent.height;
        defaultOuterDim[0] = parent.width-2*defaultPos[0];
        defaultOuterDim[1] = parent.height-2*defaultPos[1];
      }
      delay(20);
    }
  }

  class MyThread extends Thread {

    public void run() {
      windowResized();
    }
  }

  void setSurfaceTitle() {
    String surfaceTitle, x, y;
    float[] value = {0, 0};
    if ( this.isOverBox(parent.mouseX, parent.mouseY) ) {
      surfaceTitle = "Plot coordinates: ";
      value = this.getValueAt(parent.mouseX, parent.mouseY);
      x = String.format(java.util.Locale.US, "%.3g ", value[0]);
      y = String.format(java.util.Locale.US, "%.3g ", value[1]);
    } else {
      surfaceTitle = "Window pixels: ";
      x = PApplet.str(parent.mouseX);
      y = PApplet.str(parent.mouseY);
    }

    parent.getSurface().setTitle( surfaceTitle + x + "   " + y );
  }
  //
}

/**
 * ##library.name##
 * ##library.sentence##
 * ##library.url##
 *
 * Copyright ##copyright## ##author##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 * 
 * @author      ##author##
 * @modified    ##date##
 * @version     ##library.prettyVersion## (##library.version##)
 */

//package grafica;

import processing.core.PVector;

/**
 * Point class. A GPoint is composed of two coordinates (x, y) and a text label
 * 
 * @author ##author##
 */
public class GPoint {
  protected float x;
  protected float y;
  protected String label;
  protected boolean valid;

  /**
   * Constructor
   * 
   * @param x the x coordinate
   * @param y the y coordinate
   * @param label the text label
   */
  public GPoint(float x, float y, String label) {
    this.x = x;
    this.y = y;
    this.label = label;
    valid = isValidNumber(this.x) && isValidNumber(this.y);
  }

  /**
   * Constructor
   * 
   * @param x the x coordinate
   * @param y the y coordinate
   */
  public GPoint(float x, float y) {
    this(x, y, "");
  }

  /**
   * Constructor
   * 
   * @param v the Processing vector containing the point coordinates
   * @param label the text label
   */
  public GPoint(PVector v, String label) {
    this(v.x, v.y, label);
  }

  /**
   * Constructor
   * 
   * @param v the Processing vector containing the point coordinates
   */
  public GPoint(PVector v) {
    this(v.x, v.y, "");
  }

  /**
   * Constructor
   * 
   * @param point a GPoint
   */
  public GPoint(GPoint point) {
    this(point.getX(), point.getY(), point.getLabel());
  }

  /**
   * Checks if the provided number is valid (i.e., is not NaN or Infinite)
   * 
   * @param number the number to check
   * 
   * @return true if its valid
   */
  protected boolean isValidNumber(float number) {
    return !Float.isNaN(number) && !Float.isInfinite(number);
  }

  /**
   * Sets the point x and y coordinates and the label
   * 
   * @param newX the new x coordinate
   * @param newY the new y coordinate
   * @param newLabel the new point text label
   */
  public void set(float newX, float newY, String newLabel) {
    x = newX;
    y = newY;
    label = newLabel;
    valid = isValidNumber(x) && isValidNumber(y);
  }

  /**
   * Sets the point x and y coordinates and the label
   * 
   * @param point the point to use as a reference
   */
  public void set(GPoint point) {
    set(point.getX(), point.getY(), point.getLabel());
  }

  /**
   * Sets the point x and y coordinates and the label
   * 
   * @param v the Processing vector with the new point coordinates
   * @param newLabel the new point text label
   */
  public void set(PVector v, String newLabel) {
    set(v.x, v.y, newLabel);
  }

  /**
   * Sets the point x coordinate
   * 
   * @param newX the new x coordinate
   */
  public void setX(float newX) {
    x = newX;
    valid = isValidNumber(x) && isValidNumber(y);
  }

  /**
   * Sets the point y coordinate
   * 
   * @param newY the new y coordinate
   */
  public void setY(float newY) {
    y = newY;
    valid = isValidNumber(x) && isValidNumber(y);
  }

  /**
   * Sets the point x and y coordinates
   * 
   * @param newX the new x coordinate
   * @param newY the new y coordinate
   */
  public void setXY(float newX, float newY) {
    x = newX;
    y = newY;
    valid = isValidNumber(x) && isValidNumber(y);
  }

  /**
   * Sets the point x and y coordinates
   * 
   * @param v the Processing vector with the new point coordinates
   */
  public void setXY(PVector v) {
    setXY(v.x, v.y);
  }

  /**
   * Sets the point text label
   * 
   * @param newLabel the new point text label
   */
  public void setLabel(String newLabel) {
    label = newLabel;
  }

  /**
   * Returns the point x coordinate
   * 
   * @return the point x coordinate
   */
  public float getX() {
    return x;
  }

  /**
   * Returns the point y coordinate
   * 
   * @return the point y coordinate
   */
  public float getY() {
    return y;
  }

  /**
   * Returns the point text label
   * 
   * @return the point text label
   */
  public String getLabel() {
    return label;
  }

  /**
   * Returns if the point coordinates are valid or not
   * 
   * @return true if the point coordinates are valid
   */
  public boolean getValid() {
    return valid;
  }

  /**
   * Returns if the point coordinates are valid or not
   * 
   * @return true if the point coordinates are valid
   */
  public boolean isValid() {
    return valid;
  }
}

/**
 * ##library.name##
 * ##library.sentence##
 * ##library.url##
 *
 * Copyright ##copyright## ##author##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 * 
 * @author      ##author##
 * @modified    ##date##
 * @version     ##library.prettyVersion## (##library.version##)
 */

//package grafica;

import java.util.ArrayList;
import java.util.Iterator;
import processing.core.PVector;

/**
 * Array of points class.
 * 
 * @author ##author##
 */
public class GPointsArray {
  protected ArrayList<GPoint> points;

  /**
   * Constructor
   */
  public GPointsArray() {
    points = new ArrayList<GPoint>();
  }

  /**
   * Constructor
   * 
   * @param initialSize the initial estimate for the size of the array
   */
  public GPointsArray(int initialSize) {
    points = new ArrayList<GPoint>(initialSize);
  }

  /**
   * Constructor
   * 
   * @param points an array of points
   */
  public GPointsArray(GPoint[] points) {
    this.points = new ArrayList<GPoint>(points.length);

    for (int i = 0; i < points.length; i++) {
      if (points[i] != null) {
        this.points.add(new GPoint(points[i]));
      }
    }
  }

  /**
   * Constructor
   * 
   * @param points an array of points
   */
  public GPointsArray(GPointsArray points) {
    this.points = new ArrayList<GPoint>(points.getNPoints());

    for (int i = 0; i < points.getNPoints(); i++) {
      this.points.add(new GPoint(points.get(i)));
    }
  }

  /**
   * Constructor
   * 
   * @param x the points x coordinates
   * @param y the points y coordinates
   * @param labels the points text labels
   */
  public GPointsArray(float[] x, float[] y, String[] labels) {
    points = new ArrayList<GPoint>(x.length);

    for (int i = 0; i < x.length; i++) {
      points.add(new GPoint(x[i], y[i], labels[i]));
    }
  }

  /**
   * Constructor
   * 
   * @param x the points x coordinates
   * @param y the points y coordinates
   */
  public GPointsArray(float[] x, float[] y) {
    points = new ArrayList<GPoint>(x.length);

    for (int i = 0; i < x.length; i++) {
      points.add(new GPoint(x[i], y[i]));
    }
  }

  /**
   * Constructor
   * 
   * @param vectors an array of Processing vectors with the points x and y coordinates
   * @param labels the points text labels
   */
  public GPointsArray(PVector[] vectors, String[] labels) {
    points = new ArrayList<GPoint>(vectors.length);

    for (int i = 0; i < vectors.length; i++) {
      points.add(new GPoint(vectors[i], labels[i]));
    }
  }

  /**
   * Constructor
   * 
   * @param vectors an array of Processing vectors with the points x and y coordinates
   */
  public GPointsArray(PVector[] vectors) {
    points = new ArrayList<GPoint>(vectors.length);

    for (int i = 0; i < vectors.length; i++) {
      points.add(new GPoint(vectors[i]));
    }
  }

  /**
   * Constructor
   * 
   * @param vectors an arrayList of Processing vectors with the points x and y coordinates
   */
  public GPointsArray(ArrayList<PVector> vectors) {
    points = new ArrayList<GPoint>(vectors.size());

    for (int i = 0; i < vectors.size(); i++) {
      points.add(new GPoint(vectors.get(i)));
    }
  }

  /**
   * Adds a new point to the array
   * 
   * @param point the point
   */
  public void add(GPoint point) {
    points.add(new GPoint(point));
  }

  /**
   * Adds a new point to the array
   * 
   * @param x the point x coordinate
   * @param y the point y coordinate
   * @param label the point text label
   */
  public void add(float x, float y, String label) {
    points.add(new GPoint(x, y, label));
  }

  /**
   * Adds a new point to the array
   * 
   * @param x the point x coordinate
   * @param y the point y coordinate
   */
  public void add(float x, float y) {
    points.add(new GPoint(x, y));
  }

  /**
   * Adds a new point to the array
   * 
   * @param v the Processing vector with the point x and y coordinates
   * @param label the point text label
   */
  public void add(PVector v, String label) {
    points.add(new GPoint(v, label));
  }

  /**
   * Adds a new point to the array
   * 
   * @param v the Processing vector with the point x and y coordinates
   */
  public void add(PVector v) {
    points.add(new GPoint(v));
  }

  /**
   * Adds a new point to the array
   * 
   * @param index the point position
   * @param point the point
   */
  public void add(int index, GPoint point) {
    points.add(index, new GPoint(point));
  }

  /**
   * Adds a new point to the array
   * 
   * @param index the point position
   * @param x the point x coordinate
   * @param y the point y coordinate
   * @param label the point text label
   */
  public void add(int index, float x, float y, String label) {
    points.add(index, new GPoint(x, y, label));
  }

  /**
   * Adds a new point to the array
   * 
   * @param index the point position
   * @param x the point x coordinate
   * @param y the point y coordinate
   */
  public void add(int index, float x, float y) {
    points.add(index, new GPoint(x, y));
  }

  /**
   * Adds a new point to the array
   * 
   * @param index the point position
   * @param v the Processing vector with the point x and y coordinates
   * @param label the point text label
   */
  public void add(int index, PVector v, String label) {
    points.add(index, new GPoint(v, label));
  }

  /**
   * Adds a new point to the array
   * 
   * @param index the point position
   * @param v the Processing vector with the point x and y coordinates
   */
  public void add(int index, PVector v) {
    points.add(index, new GPoint(v));
  }

  /**
   * Adds a new set of points to the array
   * 
   * @param pts the new set of points
   */
  public void add(GPoint[] pts) {
    for (int i = 0; i < pts.length; i++) {
      points.add(new GPoint(pts[i]));
    }
  }

  /**
   * Adds a new set of points to the array
   * 
   * @param pts the new set of points
   */
  public void add(GPointsArray pts) {
    for (int i = 0; i < pts.getNPoints(); i++) {
      points.add(new GPoint(pts.get(i)));
    }
  }

  /**
   * Adds a new set of points to the array
   * 
   * @param x the points x coordinates
   * @param y the points y coordinates
   * @param labels the points text labels
   */
  public void add(float[] x, float[] y, String[] labels) {
    for (int i = 0; i < x.length; i++) {
      points.add(new GPoint(x[i], y[i], labels[i]));
    }
  }

  /**
   * Adds a new set of points to the array
   * 
   * @param x the points x coordinates
   * @param y the points y coordinates
   */
  public void add(float[] x, float[] y) {
    for (int i = 0; i < x.length; i++) {
      points.add(new GPoint(x[i], y[i]));
    }
  }

  /**
   * Adds a new set of points to the array
   * 
   * @param vectors the Processing vectors with the points x and y coordinates
   * @param labels the points text labels
   */
  public void add(PVector[] vectors, String[] labels) {
    for (int i = 0; i < vectors.length; i++) {
      points.add(new GPoint(vectors[i], labels[i]));
    }
  }

  /**
   * Adds a new set of points to the array
   * 
   * @param vectors the Processing vectors with the points x and y coordinates
   */
  public void add(PVector[] vectors) {
    for (int i = 0; i < vectors.length; i++) {
      points.add(new GPoint(vectors[i]));
    }
  }

  /**
   * Adds a new set of points to the array
   * 
   * @param vectors the Processing vectors with the points x and y coordinates
   */
  public void add(ArrayList<PVector> vectors) {
    for (int i = 0; i < vectors.size(); i++) {
      points.add(new GPoint(vectors.get(i)));
    }
  }

  /**
   * Removes one of the points in the array
   * 
   * @param index the point index.
   */
  public void remove(int index) {
    points.remove(index);
  }

  /**
   * Removes a range of points in the array
   * 
   * @param fromIndex the lower point index.
   * @param toIndex the end point index.
   */
  public void removeRange(int fromIndex, int toIndex) {
    points.subList(fromIndex, toIndex).clear();
  }

  /**
   * Removes invalid points from the array
   */
  public void removeInvalidPoints() {
    for (Iterator<GPoint> it = points.iterator(); it.hasNext();) {
      if (!it.next().isValid()) {
        it.remove();
      }
    }
  }

  /**
   * Sets all the points in the array
   * 
   * @param pts the new points. The number of points could differ from the original.
   */
  public void set(GPointsArray pts) {
    if (pts.getNPoints() == points.size()) {
      for (int i = 0; i < points.size(); i++) {
        points.get(i).set(pts.get(i));
      }
    } else if (pts.getNPoints() > points.size()) {
      for (int i = 0; i < points.size(); i++) {
        points.get(i).set(pts.get(i));
      }

      for (int i = points.size(); i < pts.getNPoints(); i++) {
        points.add(new GPoint(pts.get(i)));
      }
    } else {
      for (int i = 0; i < pts.getNPoints(); i++) {
        points.get(i).set(pts.get(i));
      }

      points.subList(pts.getNPoints(), points.size()).clear();
    }
  }

  /**
   * Sets the x and y coordinates and the label of a point with those from another point
   * 
   * @param index the point index. If the index equals the array size, it will add a new point to the array.
   * @param point the point to use
   */
  public void set(int index, GPoint point) {
    if (index == points.size()) {
      points.add(new GPoint(point));
    } else {
      points.get(index).set(point);
    }
  }

  /**
   * Sets the x and y coordinates of a specific point in the array
   * 
   * @param index the point index. If the index equals the array size, it will add a new point to the array.
   * @param x the point new x coordinate
   * @param y the point new y coordinate
   * @param label the point new text label
   */
  public void set(int index, float x, float y, String label) {
    if (index == points.size()) {
      points.add(new GPoint(x, y, label));
    } else {
      points.get(index).set(x, y, label);
    }
  }

  /**
   * Sets the x and y coordinates of a specific point in the array
   * 
   * @param index the point index. If the index equals the array size, it will add a new point to the array.
   * @param v the Processing vector with the point new x and y coordinates
   * @param label the point new text label
   */
  public void set(int index, PVector v, String label) {
    if (index == points.size()) {
      points.add(new GPoint(v, label));
    } else {
      points.get(index).set(v, label);
    }
  }

  /**
   * Sets the x coordinate of a specific point in the array
   * 
   * @param index the point index
   * @param x the point new x coordinate
   */
  public void setX(int index, float x) {
    points.get(index).setX(x);
  }

  /**
   * Sets the y coordinate of a specific point in the array
   * 
   * @param index the point index
   * @param y the point new y coordinate
   */
  public void setY(int index, float y) {
    points.get(index).setY(y);
  }

  /**
   * Sets the x and y coordinates of a specific point in the array
   * 
   * @param index the point index
   * @param x the point new x coordinate
   * @param y the point new y coordinate
   */
  public void setXY(int index, float x, float y) {
    points.get(index).setXY(x, y);
  }

  /**
   * Sets the x and y coordinates of a specific point in the array
   * 
   * @param index the point index
   * @param v the Processing vector with the point new x and y coordinates
   */
  public void setXY(int index, PVector v) {
    points.get(index).setXY(v);
  }

  /**
   * Sets the text label of a specific point in the array
   * 
   * @param index the point index
   * @param label the point new text label
   */
  public void setLabel(int index, String label) {
    points.get(index).setLabel(label);
  }

  /**
   * Sets the total number of points in the array
   * 
   * @param nPoints the new total number of points in the array. It should be smaller than the current number.
   */
  public void setNPoints(int nPoints) {
    points.subList(nPoints, points.size()).clear();
  }

  /**
   * Returns the total number of points in the array
   * 
   * @return the total number of points in the array
   */
  public int getNPoints() {
    return points.size();
  }

  /**
   * Returns a given point in the array
   * 
   * @param index the point index in the array
   * 
   * @return the point reference
   */
  public GPoint get(int index) {
    return points.get(index);
  }

  /**
   * Returns the x coordinate of a point in the array
   * 
   * @param index the point index in the array
   * 
   * @return the point x coordinate
   */
  public float getX(int index) {
    return points.get(index).getX();
  }

  /**
   * Returns the y coordinate of a point in the array
   * 
   * @param index the point index in the array
   * 
   * @return the point y coordinate
   */
  public float getY(int index) {
    return points.get(index).getY();
  }

  /**
   * Returns the text label of a point in the array
   * 
   * @param index the point index in the array
   * 
   * @return the point text label
   */
  public String getLabel(int index) {
    return points.get(index).getLabel();
  }

  /**
   * Returns if a point in the array is valid or not
   * 
   * @param index the point index in the array
   * 
   * @return true if the point is valid
   */
  public boolean getValid(int index) {
    return points.get(index).getValid();
  }

  /**
   * Returns if a point in the array is valid or not
   * 
   * @param index the point index in the array
   * 
   * @return true if the point is valid
   */
  public boolean isValid(int index) {
    return points.get(index).isValid();
  }

  /**
   * Returns the latest point added to the array
   * 
   * @return the latest point added to the array
   */
  public GPoint getLastPoint() {
    return (points.size() > 0) ? points.get(points.size() - 1) : null;
  }
}

/**
 * ##library.name##
 * ##library.sentence##
 * ##library.url##
 *
 * Copyright ##copyright## ##author##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 * 
 * @author      ##author##
 * @modified    ##date##
 * @version     ##library.prettyVersion## (##library.version##)
 */

//package grafica;

import processing.core.PApplet;
import processing.core.PConstants;
import processing.core.PFont;

/**
 * Title class.
 * 
 * @author ##author##
 */
public class GTitle implements PConstants {
  // The parent Processing applet
  protected final PApplet parent;

  // General properties
  protected float[] dim;
  protected float relativePos;
  protected float plotPos;
  protected float offset;

  // Text properties
  protected String text;
  protected int textAlignment;
  protected String fontName;
  protected int fontColor;
  protected int fontSize;
  protected PFont font;

  /**
   * Constructor
   * 
   * @param parent the parent Processing applet
   * @param dim the plot box dimensions in pixels
   */
  public GTitle(PApplet parent, float[] dim) {
    this.parent = parent;

    this.dim = dim.clone();
    relativePos = 0.5f;
    plotPos = relativePos * this.dim[0];
    offset = 10;

    text = "";
    textAlignment = CENTER;
    fontName = "SansSerif.bold";
    fontColor = color(100);
    fontSize = 13;
    font = this.parent.createFont(fontName, fontSize);
  }

  /**
   * Draws the plot title
   */
  public void draw() {
    parent.pushStyle();
    parent.textFont(font);
    parent.textSize(fontSize);
    parent.fill(fontColor);
    parent.noStroke();
    parent.textAlign(textAlignment, BOTTOM);
    parent.text(text, plotPos, -offset - dim[1]);
    parent.popStyle();
  }

  /**
   * Sets the plot box dimensions information
   * 
   * @param xDim the new plot box x dimension
   * @param yDim the new plot box y dimension
   */
  public void setDim(float xDim, float yDim) {
    if (xDim > 0 && yDim > 0) {
      dim[0] = xDim;
      dim[1] = yDim;
      plotPos = relativePos * dim[0];
    }
  }

  /**
   * Sets the plot box dimensions information
   * 
   * @param newDim the new plot box dimensions information
   */
  public void setDim(float[] newDim) {
    setDim(newDim[0], newDim[1]);
  }

  /**
   * Sets the title relative position in the plot
   * 
   * @param newRelativePos the new relative position in the plot
   */
  public void setRelativePos(float newRelativePos) {
    relativePos = newRelativePos;
    plotPos = relativePos * dim[0];
  }

  /**
   * Sets the title offset
   * 
   * @param newOffset the new title offset
   */
  public void setOffset(float newOffset) {
    offset = newOffset;
  }

  /**
   * Sets the title text
   * 
   * @param newText the new title text
   */
  public void setText(String newText) {
    text = newText;
  }

  /**
   * Sets the title type of text alignment
   * 
   * @param newTextAlignment the new type of text alignment
   */
  public void setTextAlignment(int newTextAlignment) {
    if (newTextAlignment == CENTER || newTextAlignment == LEFT || newTextAlignment == RIGHT) {
      textAlignment = newTextAlignment;
    }
  }

  /**
   * Sets the font name
   * 
   * @param newFontName the name of the new font
   */
  public void setFontName(String newFontName) {
    fontName = newFontName;
    font = parent.createFont(fontName, fontSize);
  }

  /**
   * Sets the font color
   * 
   * @param newFontColor the new font color
   */
  public void setFontColor(int newFontColor) {
    fontColor = newFontColor;
  }

  /**
   * Sets the font size
   * 
   * @param newFontSize the new font size
   */
  public void setFontSize(int newFontSize) {
    if (newFontSize > 0) {
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }

  /**
   * Sets all the font properties at once
   * 
   * @param newFontName the name of the new font
   * @param newFontColor the new font color
   * @param newFontSize the new font size
   */
  public void setFontProperties(String newFontName, int newFontColor, int newFontSize) {
    if (newFontSize > 0) {
      fontName = newFontName;
      fontColor = newFontColor;
      fontSize = newFontSize;
      font = parent.createFont(fontName, fontSize);
    }
  }
}
