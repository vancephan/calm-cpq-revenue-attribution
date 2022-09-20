public with sharing class ChangeAssetOrderItem {
    
    //Method that is called by flow
    @InvocableMethod(label='Change CALM Asset from Order Product' description='Calls the CALM Change Asset API using Order Product Information' category='OrderItem')
    public static void changeAsset(List<OrderItem> ois){
        for(OrderItem oi: ois){
            postToChangeCALM(oi.Id);
        }
    }

    @Future(Callout = true)
    public static void postToChangeCALM(Id oid) {
        OrderItem oi = getOrderItem(oid);

        Id assetId;

        InstallBaseAssetModel aw = constructAssetModel(oi);
      
        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        httpRequest.setHeader('Content-Type', 'application/json');

        system.debug('OAuth + Bearer Token is ' + UserInfo.getSessionId());
        
        httpRequest.setBody(JSON.serialize(aw));
        System.debug('Request Body: ' + httpRequest.getBody());
        System.debug(JSON.serializePretty(aw));
        System.debug(InstallBaseAssetModel.getSerialized(aw));

        httpRequest.setEndpoint(buildChangeRestAPIURL(oi.blng__Asset__c));

        HttpResponse response = http.send(httpRequest);

        // Parse the JSON response
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
            assetId = null;
        } else {
            System.debug(response.getBody());
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> assets = (Map<String, Object>) m.get('asset');
            if (assets != null) {
                for (String id : assets.keySet()) {
                    System.debug('*****RESPONSE CALM Asset = ' + assets.get(id));
                    assetId = (Id) assets.get(id);

                }
            }
        }       
    }

    public static InstallBaseAssetModel constructAssetModel(OrderItem oi){
        InstallBaseAssetModel ibaw = new InstallBaseAssetModel();

        ibaw.assetStatePeriods = getExistingAssetStatePeriods(oi);

        InstallBaseAssetModel.AssetActionWrapper aaw = new InstallBaseAssetModel.AssetActionWrapper();

        aaw.category = oi.AssetActionCategory__c;
        aaw.actionDate = CALMDateProcessing.getFormattedStartDate(oi.ServiceDate);
        aaw.quantityChange = oi.Quantity;
        aaw.mrrChange = (oi.MRR__c).setScale(2);
        aaw.amount = oi.TotalPrice;

        ibaw.assetAction = aaw;

        return ibaw;
    }

    public static List<InstallBaseAssetModel.AssetStatePeriodWrapper> getExistingAssetStatePeriods(OrderItem oi) {

        List<InstallBaseAssetModel.AssetStatePeriodWrapper> aspws = new List<InstallBaseAssetModel.AssetStatePeriodWrapper>();

        List<AssetStatePeriod> eASPs = [
            SELECT Id, AssetId, Quantity,
                StartDate, EndDate, Mrr
            FROM AssetStatePeriod
            WHERE AssetId = : oi.blng__Asset__c
        ];

        Date sd = oi.ServiceDate;
        Date ed = oi.EndDate;

        System.debug('OI Start Date is ' + sd);
        System.debug('OI End Date is ' + ed);

        List<Datetime> periodDateTimes = new List<Datetime>();
        periodDateTimes = CALMDateProcessing.processDatePeriods(sd, ed, eASPs);

        System.debug('Period date count is ' + periodDateTimes.size());
        System.debug('Period dates are ' + periodDateTimes);

        for (Integer i = 0; i < periodDateTimes.size() - 1; i++) {
           System.debug('Integer i is ' + i);
           Datetime sDate = periodDateTimes.get(i);
           System.debug('sDate is ' + periodDateTimes.get(i));
           Datetime eDate = periodDateTimes.get(i + 1).addSeconds(-1);
           System.debug('eDate is ' + periodDateTimes.get(i + 1).addSeconds(-1));

           AssetStatePeriod rASP = [SELECT Id, AssetId, Quantity,
                                        StartDate, EndDate, Mrr, Amount
                                    FROM AssetStatePeriod
                                    WHERE (StartDate <= :sDate AND AssetId = : oi.blng__Asset__c)
                                    ORDER BY StartDate DESC].get(0);

           Decimal rQty = rASP.Quantity;
           System.debug('rASP Quantity is ' + rASP.Quantity);

           Decimal rMRR = rASP.Mrr;
           System.debug('rASP MRR is ' + rASP.Mrr);

           Decimal rAmount = rASP.Amount;
           System.debug('rASP Amount is ' + rASP.Amount);

           Decimal nQty = 0;
           Decimal nMRR = 0;
           Decimal nAmount = 0;

            if (sDate >= oi.ServiceDate) {
                nQty = rQty + oi.Quantity;
                nMRR = rMRR + oi.MRR__c;
                nAmount = rAmount + oi.TotalPrice;
            } else {
                nQty = rQty;
                nMRR = rMRR;
                nAmount = rAmount;
            }
            InstallBaseAssetModel.AssetStatePeriodWrapper aspw = new InstallBaseAssetModel.AssetStatePeriodWrapper();

            aspw.startDate = CALMDateProcessing.formatDate(sDate);
            aspw.endDate = CALMDateProcessing.formatDate(eDate);
            aspw.quantity = nQty;
            aspw.amount = nAmount;
            aspw.mrr = nMRR;

            system.debug('ASPW is ' + aspw);

            aspws.add(aspw);
        }

        return aspws;

    }

    public static OrderItem getOrderItem(Id oid){
        
        DescribeSObjectResult describeResult = OrderItem.sObjectType.getDescribe();
  
        // Get all of the fields on the object
        List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
 
        // Build a Dynamic Query String.
        String queryString = 'SELECT ' + String.join(fieldNames, ',') + ' FROM OrderItem' + ' WHERE Id = :oid' ;

        List<OrderItem> ois = Database.query(queryString);

        OrderItem oi = ois.get(0);

        return oi;
    }

    static String buildChangeRestAPIURL(Id assetId) {
        String sfdcURL = Url.getSalesforceBaseUrl().toExternalForm();
        String restAPIURL = sfdcURL + '/services/data/v55.0/asset-management/assets/' + assetId + '/actions/change';
        System.debug('URL posted to was ' + restAPIURL);
        return restAPIURL;
    }
}