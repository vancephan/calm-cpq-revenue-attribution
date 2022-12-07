#!/bin/sh

#api version to run sfdx commands
apiversion="56.0"

defaultDir="../revenue-attribution/main"
priceRuleData="../data/price-rule-data.json";
customScriptData="../data/SBQQ__CustomScript__c.json"

function echo_attention() {
    local green='\033[0;32m'
    local no_color='\033[0m'
    echo "${green}$1${no_color}"
}

function error_and_exit() {
    local red='\033[0;31m'
    local no_color='\033[0m'
    echo "${red}$1${no_color}"
    exit 1
}

echo_attention "Pushing Revenue Attribution Salesforce org configuration in Main Default to the Org. This will take a few minutes."
sfdx force:source:deploy -p $defaultDir --apiversion=$apiversion

echo ""

echo_attention "Assigning Revenue Attribution User Permission Set"
sfdx force:user:permset:assign --permsetname CALM_Revenue_Attribution_User

echo ""

echo_attention "Pushing in Price Rule data."
sfdx force:data:tree:import -p $priceRuleData

echo ""

echo_attention "Pushing in Custom Script data."
sfdx force:data:tree:import -f $customScriptData

echo ""

echo_attention "All operations complete"