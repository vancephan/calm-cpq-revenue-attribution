export function onBeforePriceRules(quoteModel, quoteLineModels, conn) {
    if (quoteLineModels.length > 0) {
        quoteLineModels.forEach(function (line) {
            console.log('Console logging line: ', line);
            const qLine = { ql: {} };

            var qlStartDate = line.record["SBQQ__EffectiveStartDate__c"];
            console.log('Raw date is ', qlStartDate);

            var qlStartDateOutput = qlStartDate.toString();

            console.log('Converted date is ', qlStartDateOutput);


            qLine.ql.accountId = quoteModel.record["SBQQ__Account__c"];
            qLine.ql.qlId = line.record["Id"];
            qLine.ql.productId = line.record["SBQQ__Product__c"];
            qLine.ql.quantity = line.record["SBQQ__Quantity__c"];
            qLine.ql.startDate = qlStartDateOutput.toString();

            console.log('JSON message body: ', qLine);

            conn.apex.post('/CALMQueryService/queryAssetInstallBase/', qLine)
                .then(results => {
                    console.log('Results', results);

                    console.log('Product Id is ', results.prodId);
                    console.log('Aggregated quantity is ', results.quantity);
                    console.log('Aggregated MRR is ', results.assetMRR);
                    console.log('Aggregated spend is ', results.assetSpend);

                    line.record["Existing_Quantity__c"] = results.quantity;
                    line.record["Existing_MRR__c"] = results.assetMRR;
                    line.record["Existing_Spend__c"] = results.assetSpend;
                })
                .catch(error => {
                    console.log('Error', error);

                });
        });
    }

    return Promise.resolve();
};