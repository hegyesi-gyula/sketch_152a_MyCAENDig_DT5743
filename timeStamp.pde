//for formatting date and time:
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Calendar;

String getTimeStampForFilename() {
  //SimpleDateFormat formatter= new SimpleDateFormat("yyyy-MM-dd-'at'-HH-mm-ss");
  SimpleDateFormat formatter= new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss");
  Date date = new Date();
  return formatter.format(date);
}

String getTimeStamp(int secOffset) {
  SimpleDateFormat formatter= new SimpleDateFormat("yyyy/MM/dd'  \t'HH:mm:ss");
  Date date = new Date();

  // Convert Date to Calendar
  Calendar c = Calendar.getInstance();
  c.setTime(date); 
  c.add(Calendar.SECOND, secOffset);

  // Convert calendar back to Date
  Date date1 = c.getTime();
  return formatter.format(date1);
}
