global class AssetModel {
    global String accountId;
    global String assetName;
    global Id productId;
    global String currencyIsoCode;
    global List<AssetStatePeriodWrapper> assetStatePeriods;
    global AssetActionWrapper assetAction;

    global class AssetStatePeriodWrapper{
        public String startDate;
        public String endDate;
        public Double quantity;
        public Double amount;
        public Double mrr;
    }

    global class AssetActionWrapper{
        public String category;
        public String actionDate;
        public Double quantityChange;
        public Double mrrChange;
        public Double amount;
    }

    public static String getSerialized(AssetModel aw) {
        Map<String, Object> r = new Map<String, Object>();
        r.put('accountId', aw.accountId);
        r.put('assetName', aw.assetName);
        r.put('productId', aw.productId);
        r.put('currencyIsoCode', aw.currencyIsoCode);
        r.put('assetStatePeriods', aw.assetStatePeriods);
        r.put('assetAction', aw.assetAction);
        return JSON.serialize(r);
    }
}