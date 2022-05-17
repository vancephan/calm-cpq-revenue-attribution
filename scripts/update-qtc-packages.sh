#!/bin/sh

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

echo_attention "Installing Salesforce CPQ 238 Package"
sfdx force:package:install --package 04t4N000000GkWMQA0 -s AllUsers

echo_attention "Installing Latest Salesforce Billing 238 Package"
sfdx force:package:install --package 04t0K000000wUsQQAU -s AllUsers

echo ""