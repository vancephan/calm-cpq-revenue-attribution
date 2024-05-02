public  class GenerateAssetOrderItem {
    //Method that is called by flow
    @InvocableMethod(label='Generate CALM Asset from Order Product' description='Calls the CALM Generate Asset API using Order Product Information' category='OrderItem')
    public static void generateAsset(List<OrderItem> ois){
        for(OrderItem oi: ois){
            postToGenerateCALM(oi.Id);
        }
    }

    public static AssetModel constructAssetModel(OrderItem oi){
        //Get Account ID from parent Order

        Id acctId = [SELECT Id, AccountId 
                    FROM Order 
                    WHERE Id =: oi.OrderId].get(0).AccountId;

        System.debug('Order Account ID is ' + acctId);

        //Instantiate new AssetModel
        AssetModel aw = new AssetModel();

        //Set first level CALM Asset attributes
        aw.accountId = acctId;
        aw.assetName = oi.Product_Name__c;
        aw.productId = oi.Product2Id;
        aw.currencyIsoCode = oi.CurrencyIsoCode;

        system.debug('aw.accountId is ' + aw.accountId);
        system.debug('aw.assetName is ' + aw.assetName);
        system.debug('aw.productId is ' + aw.productId);
        system.debug('aw.currencyIsoCode is ' + aw.currencyIsoCode);


        //Defining Asset State Period array
        aw.assetStatePeriods = new List<AssetModel.AssetStatePeriodWrapper>();

        AssetModel.AssetStatePeriodWrapper aspw = new AssetModel.AssetStatePeriodWrapper();

        aspw.startDate = CALMDateProcessing.getFormattedStartDate(oi.ServiceDate);
        aspw.endDate = CALMDateProcessing.getFormattedEndDate(oi.EndDate);
        aspw.quantity = oi.Quantity;
        aspw.amount = oi.TotalPrice;
        aspw.mrr = oi.MRR__c;
        

        system.debug('ASPW is ' + aspw);

        aw.assetStatePeriods.add(aspw);

        //Defining Asset Action Wrapper array

        AssetModel.AssetActionWrapper aaw = new AssetModel.AssetActionWrapper();
        aaw.category = oi.AssetActionCategory__c;
        aaw.actionDate = CALMDateProcessing.getFormattedStartDate(Date.today());
        aaw.quantityChange = oi.Quantity;
        aaw.mrrChange = oi.MRR__c;
        aaw.amount = oi.TotalPrice;

        aw.assetAction = aaw;

        return aw;
    }

    @Future(Callout = true)
    public static void postToGenerateCALM(Id oid) {
        OrderItem oi = getOrderItem(oid);

        Id assetId;

        AssetModel aw = constructAssetModel(oi);
      
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
        System.debug(AssetModel.getSerialized(aw));

        httpRequest.setEndpoint(buildGenerateRestAPIURL());

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
                    
                    updateOrderItem(oi, assetId);
                }
            }
        }
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

    public static void updateOrderItem(OrderItem oi, Id assetId){
        oi.blng__Asset__c = assetId;
        oi.CALM_Generate_Successful__c = TRUE;
        database.update(oi);
    }

    static String buildGenerateRestAPIURL() {
        String sfdcURL = Url.getSalesforceBaseUrl().toExternalForm();
        String restAPIURL = sfdcURL + '/services/data/v60.0/asset-management/assets/actions/generate';
        system.debug(restAPIURL);
        return restAPIURL;
    }
   
}