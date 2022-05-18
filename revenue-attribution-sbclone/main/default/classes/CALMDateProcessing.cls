public class CALMDateProcessing {
   
   public static String getFormattedStartDate(Date sDate){
      Datetime sDateTime = processStartDateTime(sDate);
      String formattedStartDate = formatDate(sDateTime);
      return formattedStartDate;
   }

   public static String getFormattedEndDate(Date eDate){
      Datetime eDateTime = processEndDateTime(eDate);
      String formattedEndDate = formatDate(eDateTime);
      return formattedEndDate;
   }

   public static String formatDate(Datetime rawDate) {
      Datetime rawDateTime = rawDate;
      String formattedDate = rawDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
      System.debug(formattedDate);
      return formattedDate;
   }

   public static Datetime processStartDateTime(Date sDate) {
      return Datetime.newInstanceGmt(sDate.year(), sDate.month(), sDate.day(), 0, 0, 0);
   }

   public static Datetime processEndDateTime(Date eDate) {
      return Datetime.newInstanceGmt(eDate.year(), eDate.month(), eDate.day(), 23, 59, 59);
   }

   public static Date convertDateTime(Datetime dT) {
      return Date.newInstance(dT.year(), dT.month(), dT.day());
   }

   public static List<Datetime> processDatePeriods(Date sd, Date ed, List<AssetStatePeriod> easps) {
      Set<Datetime> dateTimeSet = new Set<Datetime>();

      dateTimeSet.add(processStartDateTime(sd));
      dateTimeSet.add(processEndDateTime(ed).addSeconds(1));
      //dateTimeSet.add(processEndDateTime(ed));

      System.debug('SD date input is ' + processStartDateTime(sd));
      System.debug('ED date input is ' + processEndDateTime(ed).addSeconds(1));
      //system.debug('ED date input is ' + processEndDateTime(ed));


      for (AssetStatePeriod easp : easps) {
         dateTimeSet.add(easp.StartDate);
         dateTimeSet.add((easp.EndDate).addSeconds(1));

         System.debug('EA SD date input is ' + easp.StartDate);
         System.debug('EA ED date input is ' + (easp.EndDate).addSeconds(1));

      }

      List<Datetime> dateList = new List<Datetime>();
      dateList.addAll(dateTimeSet);
      dateList.sort();

      return dateList;
   }
}