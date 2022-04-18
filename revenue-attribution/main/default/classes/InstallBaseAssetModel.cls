global class InstallBaseAssetModel {
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

    public static String getSerialized(InstallBaseAssetModel aw) {
        Map<String, Object> r = new Map<String, Object>();
        r.put('assetStatePeriods', aw.assetStatePeriods);
        r.put('assetAction', aw.assetAction);
        return JSON.serialize(r);
    }

}