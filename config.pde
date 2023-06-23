/**
 * JTable Example II (v1.0.2)
 * GoToLoop (2019/Jan/01)
 * https://Discourse.Processing.org/t/filling-dinamyc-arrays/7049/5
 */

// Imports for creating a frame:
import javax.swing.DefaultCellEditor;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JScrollPane;
import java.awt.BorderLayout;

// Import for creating a table:
import javax.swing.JTable;
import javax.swing.table.TableColumn;
import javax.swing.table.TableColumnModel;
import javax.swing.table.JTableHeader;
import java.awt.FontMetrics;
import javax.swing.event.TableModelEvent;
import javax.swing.event.TableModelListener;
import javax.swing.table.DefaultTableCellRenderer;

import java.util.Arrays;

String[] configLines;
int headerIndex;
String[] header;
//Table configTable;
int postTrigPercentIndex;
MyJTable channelConfigTable;
MyRowHeaderTable globalConfigTable;
JFrame frameChConfig, frameGlConfig;

int globalParamsBeginIndex = 0;
int globalParamsEndIndex = 0;
int channelParamsBeginIndex = 0;
int channelParamsEndIndex = 0;
int lastUsedAdcNChIndex = 0;
int lastUsedAdcNChannels = 0;

boolean config() {

  // Load lines
  configLines = loadStrings("config.txt");

  // If there is no config.txt file in the sketch folder:
  if (configLines == null ) {
    println(" NO config.txt");
    consolFile.println(" NO config.txt");
    return false;
  }


  //// Rename configPrev.txt to configPrev1.txt
  //String[] configLinesPrev = loadStrings("configPrev.txt");
  //if (configLinesPrev != null ) {
  //  PrintWriter configPrev1 = createWriter("data/configPrev1.txt");
  //  for (String line : configLinesPrev) configPrev1.println(line);
  //  configPrev1.flush();  // Writes the remaining data to the file
  //  configPrev1.close();  // Finishes the file
  //}


  //// Preserve loaded config file in configPrev.txt
  //PrintWriter configPrev = createWriter("data/configPrev.txt");
  //for (String line : configLines) configPrev.println(line);
  //configPrev.flush();  // Writes the remaining data to the file
  //configPrev.close();  // Finishes the file


  // Preserve loaded config file in configPrev.txt
  PrintWriter configTimestamp = createWriter("data/timestamped_config_files/config_" + getTimeStampForFilename() + ".txt");
  for (String line : configLines) configTimestamp.println(line);
  configTimestamp.flush();  // Writes the remaining data to the file
  configTimestamp.close();  // Finishes the file


  String[] globalConfigRowNames = {};
  String[] globalConfigData = {};

  // find global config params begin index
  for ( int i = 0; i < configLines.length; i++ ) {
    if ( configLines[i].contains("global config params begin") ) {
      globalParamsBeginIndex = i + 2;
      //println("globalParamsBeginIndex = " + globalParamsBeginIndex);
      break;
    }
  }

  // find global config params end index
  for ( int i = 0; i < configLines.length; i++ ) {
    if ( configLines[i].contains("global config params end") ) {
      globalParamsEndIndex = i - 2;
      //println("globalParamsEndIndex = " + globalParamsEndIndex);
      break;
    }
  }

  // get global config row names and data
  for (int i = globalParamsBeginIndex; i <= globalParamsEndIndex; i++) {
    // Line pieces can be separated by any whitespace character. Unlike the split() function,
    // multiple adjacent delimiters are treated as a single break.
    String[] line = splitTokens(configLines[i]);
    globalConfigRowNames = append(globalConfigRowNames, line[0]);
    globalConfigData = append(globalConfigData, line[1]);
  }

  // dummy 2D array for the globalConfig MyRowHeaderTable
  String[][] globalConfigData2d = new String[globalConfigData.length][1];
  for ( int i=0; i<globalConfigData.length; i++ ) {
    globalConfigData2d[i][0] = globalConfigData[i];
  }

  // dummy column names for the globalConfig MyRowHeaderTable
  String[] globalConfigColumnNames = new String[globalConfigData2d[0].length];
  Arrays.fill(globalConfigColumnNames, "value");

  // Initializing the globalConfig MyRowHeaderTable
  globalConfigTable = new MyRowHeaderTable(globalConfigData2d, globalConfigColumnNames, globalConfigRowNames);

  // initialize frequently used global config variables
  serIsEnabled =  globalConfigTable.getValueAt("SER", 0).equals("Enabled");
  saveToFileIsEnabled =  globalConfigTable.getValueAt("saveToFile", 0).equals("Enabled");
  recordLength = globalConfigTable.getInt("recordLength", 0);
  // in case of x743, the allowed sizes are those for which: size mod 16 = 0:
  recordLength = recordLength - recordLength % 16;
  postTrigPercent = globalConfigTable.getInt("postTrigPercent", 0);


  JComboBox comboBox = new JComboBox();
  comboBox.addItem("Enabled");
  comboBox.addItem("Disabled");
  globalConfigTable.setRowCellEditor(new DefaultCellEditor(comboBox), "saveToFile");
  globalConfigTable.setRowCellEditor(new DefaultCellEditor(comboBox), "SER");

  comboBox = new JComboBox();
  comboBox.addItem("0");
  comboBox.addItem("1");
  comboBox.addItem("2");
  globalConfigTable.setRowCellEditor(new DefaultCellEditor(comboBox), "USBLinkNum");

  comboBox = new JComboBox();
  comboBox.addItem("0");
  comboBox.addItem("32100000");
  comboBox.addItem("32110000");
  globalConfigTable.setRowCellEditor(new DefaultCellEditor(comboBox), "VMEBaseAddress");
  
  comboBox = new JComboBox();
  comboBox.addItem("caen");
  comboBox.addItem("systemSec");
  globalConfigTable.setRowCellEditor(new DefaultCellEditor(comboBox), "timestamp");
  
  comboBox = new JComboBox();
  comboBox.addItem("no");
  comboBox.addItem("yes");
  globalConfigTable.setRowCellEditor(new DefaultCellEditor(comboBox), "ch0TrigIsCommon");
  
  comboBox = new JComboBox();
  comboBox.addItem("0.3125");
  comboBox.addItem("0.625");
  comboBox.addItem("1.25");
  comboBox.addItem("2.5");
  globalConfigTable.setRowCellEditor(new DefaultCellEditor(comboBox), "DT5743Period_(ns)_");

  globalConfigTable.setToolTip("acquire Single Electron Response spectrum before and after the main scint. pulse", "SER", 0);
  globalConfigTable.setToolTip("Save To File", "saveToFile", 0);
  globalConfigTable.setToolTip("USB link numbers are assigned by the PC when you connect the cable to the device; it is 0 for the first device", "USBLinkNum", 0);
  globalConfigTable.setToolTip("Base Address of the board as a hex number through the VME bus. It MUST BE 0 in all other cases.", "VMEBaseAddress", 0);
  globalConfigTable.setToolTip("number of samples in the acquisition window", "recordLength", 0);
  globalConfigTable.setToolTip("position of the trigger within the acquisition window expressed in the percentage of the record length", "postTrigPercent", 0);
  globalConfigTable.setToolTip("the maximum number of events for each block transfer from the digitizer", "maxNumEventsBLT", 0);
  globalConfigTable.setToolTip("keep events only if pulse integral is within ROI for at least this number of channels", "multiplicity", 0);
  globalConfigTable.setToolTip("CAEN Trigger Time Tag or PC system time in sec.", "timestamp", 0);
  globalConfigTable.setToolTip("send sw trigger after autoTrigSec if saveToFile is NOT enabled", "autoTrigSec", 0);
  globalConfigTable.setToolTip("use ch0 trig. pos. for other enabled channels", "ch0TrigIsCommon", 0);
  globalConfigTable.setToolTip("click to select DT5743 sampling period (in ns)", "DT5743Period_(ns)_", 0);


  // find table header index
  headerIndex = 0;
  for ( int i = 0; i < configLines.length; i++ ) {
    if ( trim(configLines[i]).startsWith("id") ) {
      headerIndex = i;
      break;
    }
  }
  //println(headerIndex);


  // find channel config params begin index
  for ( int i = 0; i < configLines.length; i++ ) {
    if ( configLines[i].contains("channel config params begin") ) {
      channelParamsBeginIndex = i + 2;
      //println("channelParamsBeginIndex = " + channelParamsBeginIndex);
      break;
    }
  }

  // find channel config params end index
  for ( int i = 0; i < configLines.length; i++ ) {
    if ( configLines[i].contains("channel config params end") ) {
      channelParamsEndIndex = i - 2;
      //println("channelParamsEndIndex = " + channelParamsEndIndex);
      break;
    }
  }


  // create table header array
  header = splitTokens(configLines[channelParamsBeginIndex]);
  //printArray(header);

  // create 2D array for table rows
  String [][] rows = new String [17][];
  for ( int i = 0; i < rows.length; i++ ) {
    rows[i] = splitTokens( configLines[channelParamsBeginIndex+1+i] );
    //printArray(rows[i]);
  }


  // Initializing the channelConfig JTable
  channelConfigTable = new MyJTable(rows, header) {
    // Disable edit on certain columns in a JTable
    public boolean isCellEditable(int rowIndex, int colIndex) {
      return colIndex != 0;
    }
  };


  TableColumn onColumn = channelConfigTable.getColumn("on");
  comboBox = new JComboBox();
  comboBox.addItem("0");
  comboBox.addItem("1");
  onColumn.setCellEditor(new DefaultCellEditor(comboBox));

  TableColumn trigColumn = channelConfigTable.getColumn("trig");
  trigColumn.setCellEditor(new DefaultCellEditor(comboBox));

  TableColumn trPolColumn = channelConfigTable.getColumn("tr.pol");
  comboBox = new JComboBox();
  comboBox.addItem("pos");
  comboBox.addItem("neg");
  trPolColumn.setCellEditor(new DefaultCellEditor(comboBox));

  // Set up tool tips for the thres cells.
  DefaultTableCellRenderer renderer = new DefaultTableCellRenderer();
  renderer.setToolTipText("Trigger threshold");
  //TableColumn thresColumn = channelConfigTable.getColumn("thres");
  //thresColumn.setCellRenderer(renderer);
  channelConfigTable.getColumn("thres").setCellRenderer(renderer);


  channelConfigTable.getModel().addTableModelListener(
    new TableModelListener() {
    public void tableChanged(TableModelEvent e) {
      //println( "channelConfigTable has changed at  " + e.getFirstRow() + "\t" + e.getColumn() );
    }
  }
  );


  // set column widths resizable
  //channelConfigTable.getTableHeader().setResizingAllowed(true);

  // autosize column width based on header content
  JTableHeader tableHeader = channelConfigTable.getTableHeader();
  FontMetrics headerFontMetrics = tableHeader.getFontMetrics(tableHeader.getFont());
  TableColumnModel columnModel = channelConfigTable.getColumnModel();
  for (int i = 0; i < channelConfigTable.getColumnCount(); i++) {
    String colName = channelConfigTable.getColumnName(i);
    //int colWidth = colName.length()*8 + 12;
    int headerWidth = headerFontMetrics.stringWidth(colName);
    columnModel.getColumn(i).setPreferredWidth(headerWidth+20);
    //columnModel.getColumn(i).setMinWidth(headerWidth+20);
  }



  //  JTable must not auto-resize the columns
  //channelConfigTable.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);

  //jt.setTableHeader(null);  // hide column header

  // Creates a separate frame to display the table:
  frameChConfig = new JFrame();
  frameChConfig.add(new JScrollPane(channelConfigTable));
  //f.add(new JScrollPane(jt, JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED, JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED));
  //frameChConfig.setVisible(true);
  //f1.setSize(600, 350);
  frameChConfig.setSize(600, channelConfigTable.getRowHeight()*channelConfigTable.getRowCount()+65);
  frameChConfig.setTitle("Channel Config");

  frameGlConfig = new JFrame();
  frameGlConfig.add(globalConfigTable.scroll, BorderLayout.CENTER);
  //f2.setSize(300, 180);
  frameGlConfig.setSize(300, globalConfigTable.getRowHeight()*globalConfigTable.getRowCount()+45);
  frameGlConfig.setLocationRelativeTo(null);  // window is placed in the center of the screen
  frameGlConfig.setTitle("Global Config");
  //frameGlConfig.setVisible(true);


  // find number of channels of last used ADC index
  for ( int i = 0; i < configLines.length; i++ ) {
    if ( configLines[i].contains("number of channels of last used ADC") ) {
      lastUsedAdcNChIndex = i + 1;
      //println("lastUsedAdcNChIndex = " + lastUsedAdcNChIndex);
      break;
    }
  }

  // add missing lines for legacy config.txt
  if (lastUsedAdcNChIndex == 0) {
    int prevLength = configLines.length;
    configLines = Arrays.copyOf(configLines, prevLength + 3);
    configLines[prevLength + 0] = "";
    configLines[prevLength + 1] = "# number of channels of last used ADC";
    configLines[prevLength + 2] = "16000";
    lastUsedAdcNChIndex = prevLength + 2;
  }

  String[] line = splitTokens(configLines[lastUsedAdcNChIndex]);
  lastUsedAdcNChannels = int (line[0] );
  println("lastUsedAdcNChannels = " + lastUsedAdcNChannels);
  consolFile.println("lastUsedAdcNChannels = " + lastUsedAdcNChannels);
  adcNChannels = lastUsedAdcNChannels; // for safety reasons



  return true;
}



void updateConfigFile() {

  // get length of longest rowHeader item
  int maxRowHeaderLength = 0;
  for ( int i = 0; i < globalConfigTable.getRowCount(); i++ ) {
    String s = (String) globalConfigTable.rowHeader.getModel().getElementAt(i);
    maxRowHeaderLength = max( maxRowHeaderLength, s.length() );
  }

  PrintWriter configNew = createWriter("data/config.txt");
  for ( int i = 0; i < configLines.length; i++ ) {

    String lineToPrint = configLines[i];

    if (i >= globalParamsBeginIndex && i <= globalParamsEndIndex) {
      int rowIndex = i - globalParamsBeginIndex;
      lineToPrint = (String) globalConfigTable.rowHeader.getModel().getElementAt(rowIndex);
      //lineToPrint = String.format("%-12s", lineToPrint);  // pads string with trailing spaces to fixed length
      lineToPrint = String.format("%-" + (maxRowHeaderLength+4) + "s", lineToPrint);  // pads string with trailing spaces to fixed length
      lineToPrint += (String) globalConfigTable.getValueAt(rowIndex, 0);
    }

    if (i == channelParamsBeginIndex) {
      lineToPrint = "";
      for (String s : header) {
        //s = String.format("%-7s", s);  // pads string with trailing spaces to fixed length
        s = String.format("%-" + (s.length()+2) + "s", s);  // pads string with trailing spaces to variable length
        lineToPrint += s;
      }
    }

    if (i > channelParamsBeginIndex && i <= channelParamsEndIndex) {
      lineToPrint = "";
      String s = "";
      int rowIndex = i - channelParamsBeginIndex - 1;
      for (int columnIndex = 0; columnIndex < channelConfigTable.getColumnCount(); columnIndex++) {
        s = (String) channelConfigTable.getValueAt(rowIndex, columnIndex);
        //s = String.format("%-7s", s);  // pads string with trailing spaces to fixed length
        s = String.format("%-" + (header[columnIndex].length()+2) + "s", s);  // pads string with trailing spaces to fixed length
        lineToPrint += s;
      }
    }

    if (i == lastUsedAdcNChIndex) {
      lineToPrint = str(adcNChannels);
    }

    configNew.println( lineToPrint );
    //println( lineToPrint );
  }  // for ( int i = 0; i < configLines.length; i++ )

  configNew.flush();  // Writes the remaining data to the file
  configNew.close();  // Finishes the file

  // save table in html format
  //saveTable(configTable, "data/table.html", "html");
  channelConfigTable.saveJTable( "data/channelConfigTable.html", "html");
  globalConfigTable.saveJTable( "data/globalConfigTable.html", "html");
}



//void displayConfigTable() {

//  String lineToPrint = "";

//  for (String s : header) {
//    s = String.format("%-" + (s.length()+2) + "s", s);  // pads string with trailing spaces to variable length
//    lineToPrint += s;
//  }
//  text(lineToPrint, 10, 25);

//  //for ( int rowIndex = 0; rowIndex < configTable.getRowCount(); rowIndex++ ) {
//  for ( int rowIndex = 0; rowIndex < channelConfigTable.getRowCount(); rowIndex++ ) {
//    lineToPrint = "";
//    String s = "";
//    for (int columnIndex = 0; columnIndex < channelConfigTable.getColumnCount(); columnIndex++) {
//      s = (String) channelConfigTable.getValueAt(rowIndex, columnIndex);
//      s = String.format("%-" + (header[columnIndex].length()+2) + "s", s);  // pads string with trailing spaces to fixed length
//      lineToPrint += s;
//    }
//    text(lineToPrint, 10, 25*(rowIndex+2));
//  }
//}


//void keyPressed() {
//  if (key == ' ')   f1.setVisible(true);
//}
