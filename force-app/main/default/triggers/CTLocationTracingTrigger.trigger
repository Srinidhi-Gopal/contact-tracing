trigger CTLocationTracingTrigger on Location_Tracing__c (before insert) {
    switch on Trigger.operationType{
        WHEN BEFORE_INSERT{
            CTLocationTracingTriggerHandler.beforeInsertHandler(Trigger.new);
        }
    }
}