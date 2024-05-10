public with sharing class CTPeopleTracingTriggerHandler {
    public static void beforeInsertHandler(List<People_Tracing__c> newPeopleTraces){
        List<People_Tracing__c> duplicates = CTPeopleTracingController.checkDuplicates(newPeopleTraces);
        for(People_Tracing__c pt: duplicates){
            pt.addError('Duplicate Record Found | Person 1: ' + pt.Person_1__c + ' | Person 2: ' + pt.Person_2__c);
        }
    }
}
