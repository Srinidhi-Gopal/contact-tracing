public with sharing class CTLocationTracingTriggerHandler {
    public static void beforeInsertHandler(List<Location_Tracing__c> newLocationTraces){
        List<Location_Tracing__c> duplicates = CTLocationTracingController.checkDuplicates(newLocationTraces);
        for(Location_Tracing__c lt: duplicates){
            lt.addError('Duplicate Record Found | Person: ' + lt.Person__c + ' | Location: ' + lt.Location__c);
        }
    }
}
