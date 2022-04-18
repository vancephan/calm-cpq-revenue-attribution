@RestResource(urlMapping='/CALMQueryService/*')
global with sharing class CALMQueryService {

    global class quoteLine{
        global String accountId;
        global String qlId;
        global String productId;
        global Integer quantity;
        global String startDate;
    }

    global class assetInfo{
        global String prodId;
        global Decimal quantity;
        global Decimal assetMRR;
        global Decimal assetSpend;
    }

    @HttpPost
    global static assetInfo queryAssetInstallBase(quoteLine ql){
        Date quotedStartDate = Date.valueOf(ql.startDate);

        system.debug('Date is ' + quotedStartDate);

        List<Asset> assets = new List<Asset>();

        assets = [SELECT Id, AccountId, Product2Id, LifecycleStartDate, LifecycleEndDate
                    FROM Asset
                    WHERE (AccountId =: ql.accountId AND Product2Id =: ql.productId AND (LifecycleStartDate <=: quotedStartDate AND LifecycleEndDate >: quotedStartDate))];

        system.debug('Count of assets is ' + assets.size());

        assetInfo ai = new assetInfo();

        if(assets.size() > 0){
            List<Id> astIds = new List<Id>();

            for(Asset ast: assets){
                astIds.add(ast.Id);
            }

            AggregateResult[] groupedResults = [SELECT SUM(Quantity)qty, 
                                                SUM(Mrr)mr, SUM(Amount)amt
                                                FROM AssetStatePeriod
                                                WHERE AssetId IN: astIds];

            ai.prodId = ql.productId;
            ai.quantity = (Decimal)groupedResults[0].get('qty');
            ai.assetMRR = (Decimal)groupedResults[0].get('mr');
            ai.assetSpend = (Decimal)groupedResults[0].get('amt');
            
        }else{
            ai.prodId = null;
            ai.quantity = 0;
            ai.assetMRR = 0;
            ai.assetSpend = 0;
        }

        system.debug('Asset Info prodId is ' + ai.prodId);
        system.debug('Asset Info quantity is ' + ai.quantity);
        system.debug('Asset Info assetMRR is ' + ai.assetMRR);
        system.debug('Asset Info assetSpend is ' + ai.assetSpend);
        return ai;
    }
}