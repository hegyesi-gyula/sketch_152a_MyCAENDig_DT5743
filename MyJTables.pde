import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.ListCellRenderer;
import javax.swing.ListModel;
import javax.swing.UIManager;
import javax.swing.table.JTableHeader;
import javax.swing.table.*;
import javax.swing.JComponent;
import java.awt.Component;
import javax.swing.DefaultCellEditor;

class MyJTable extends JTable {

  MyJTable(Object [][] rows, Object [] colNames) {
    super(rows, colNames);
  }

  // get column index of Jtable by its column name
  private int getColumnIndex(String name) {
    for (int i = 0; i < getColumnCount(); ++i)
      if (getColumnName(i).equals(name))
        return i;
    println("=====ERROR=====> cannot find " + name);
    return -1;
  }

  Object getValueAt(int rowIndex, String columnName) {
    int columnIndex = getColumnIndex(columnName);
    return getValueAt(rowIndex, columnIndex);
  }

  int getInt(int rowIndex, String columnName) {
    return Integer.parseInt( (String)getValueAt(rowIndex, columnName) );
  }

  void setValueAt(Object aValue, int rowIndex, String columnName) {
    int columnIndex = getColumnIndex(columnName);
    setValueAt(aValue, rowIndex, columnIndex);
  }

  void setInt(int i, int rowIndex, String columnName) {
    setValueAt( str(i), rowIndex, columnName );
  }

  void saveJTable(String filename, String options) {
    Table pTable = new Table();

    for (int i = 0; i < getColumnCount(); ++i) {
      String s = getColumnName(i);
      pTable.addColumn(s);
    }

    for (int i = 0; i < pTable.getColumnCount(); ++i) {
      for (int j = 0; j < getRowCount(); ++j) {
        String s = (String) getValueAt(j, i);
        pTable.setString(j, i, s);
      }
    }

    saveTable(pTable, filename, options);
  }
}


class MyRowHeaderTable extends MyJTable {
  JList rowHeader;
  JScrollPane scroll;
  DefaultCellEditor [] dceArray;
  String [][] toolTipMatrix;

  MyRowHeaderTable(Object [][] rows, Object [] colNames, Object [] rowNames) {
    super(rows, colNames);
    rowHeader = new JList(rowNames);
    //rowHeader.setFixedCellWidth(150);
    rowHeader.setFixedCellHeight( getRowHeight() );
    rowHeader.setCellRenderer( new RowHeaderRenderer() );
    setTableHeader(null);  // hide column header
    scroll = new JScrollPane(this);
    scroll.setRowHeaderView(rowHeader);
    dceArray = new DefaultCellEditor[rows.length];
    for (int i = 0; i < rows.length; i++) {
      dceArray[i] = (DefaultCellEditor)super.getCellEditor(1, 0);
    }
    toolTipMatrix = new String[rows.length][rows[0].length];
  }

  // get row index of Jtable by its row name
  private int getRowIndex(String name) {
    for (int i = 0; i < getRowCount(); ++i)
      if (rowHeader.getModel().getElementAt(i).equals(name))
        return i;
    println("=====ERROR=====> cannot find " + name);
    return -1;
  }

  Object getValueAt(String rowName, int columnIndex) {
    int rowIndex = getRowIndex(rowName);
    return getValueAt(rowIndex, columnIndex);
  }

  int getInt(String rowName, int columnIndex) {
    return Integer.parseInt( (String)getValueAt(rowName, columnIndex) );
  }


  void setValueAt(Object aValue, String rowName, int columnIndex) {
    int rowIndex = getRowIndex(rowName);
    setValueAt(aValue, rowIndex, columnIndex);
  }

  void setInt(int i, String rowName, int columnIndex) {
    setValueAt( str(i), rowName, columnIndex );
  }


  class RowHeaderRenderer extends JLabel implements ListCellRenderer {

    RowHeaderRenderer() {
      JTableHeader header = getTableHeader();
      setOpaque(true);
      setBorder(UIManager.getBorder("TableHeader.cellBorder"));
      setHorizontalAlignment(LEFT);
      setForeground(header.getForeground());
      setBackground(header.getBackground());
      setFont(header.getFont());
    }

    public Component getListCellRendererComponent(
      JList list,
      Object value,
      int index,
      boolean isSelected,
      boolean cellHasFocus) {

      setText((value == null) ? "" : value.toString());
      return this;
    }
  }

  public void setRowCellEditor(DefaultCellEditor dce, String rowName) {
    int rowIndex = getRowIndex(rowName);
    //println(rowName);
    dceArray[rowIndex] = dce;
  }

  public void setToolTip(String toolTip, String rowName, int column) {
    int rowIndex = getRowIndex(rowName);
    toolTipMatrix[rowIndex][column] = toolTip;
  }

  //  Determine editor to be used by row
  public TableCellEditor getCellEditor(int row, int column) {
    return dceArray[row];
  }

  public Component prepareRenderer(TableCellRenderer renderer, int row, int column) {
    Component c = super.prepareRenderer(renderer, row, column);
    if (c instanceof JComponent) {
      JComponent jc = (JComponent) c;
      //jc.setToolTipText(getValueAt(row, column).toString());
      jc.setToolTipText(toolTipMatrix[row][column]);
    }
    return c;
  }

  void saveJTable(String filename, String options) {
    Table pTable = new Table();

    pTable.addColumn("parameter");
    for (int i = 0; i < getColumnCount(); ++i) {
      String s = getColumnName(i);
      pTable.addColumn(s);
    }

    for (int rowIndex = 0; rowIndex < getRowCount(); rowIndex++) {
      String s1 = (String) rowHeader.getModel().getElementAt(rowIndex);
      String s2 = (String) getValueAt(rowIndex, 0);
      pTable.setString(rowIndex, 0, s1);
      pTable.setString(rowIndex, 1, s2);
    }

    saveTable(pTable, filename, options);
  }
}
