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
