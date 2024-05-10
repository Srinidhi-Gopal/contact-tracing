trigger CTLocationTrigger on Location__c (before insert, before update, after update) {
    switch on Trigger.operationType{
        WHEN BEFORE_INSERT{
            CTLocationTriggerHandler.beforeInsertHandler(Trigger.new);
        }
        WHEN BEFORE_UPDATE{
            CTLocationTriggerHandler.beforeUpdateHandler(Trigger.new, Trigger.oldMap);
        }
        WHEN AFTER_UPDATE{
            CTLocationTriggerHandler.afterUpdateHandler(Trigger.new, Trigger.oldMap);
        }
    }
}