/**
 * @Description: Location  Class Controller for the Contract Tracing Application
 * @Author: Srinidhi Gopal
 * @Last Modified On: 5May2024
 * @Last Modified By: Srinidhi Gopal
 * @Modification Logs
 * Ver  Date        Author              Modification
 * 1.0  5May2024    Srinidhi Gopal      Added getRecentStatusChanges, searchLocations, getLocationById Methods
 * 1.1  
 */

public with sharing class CTLocationController {
    
    /**
     * Get latest 100 locations
     * @return List<Location__c> 
     */
    public static List<Location__c> getRecentStatusChanges(){
        return [
            SELECT Id, 
                   Name, 
                   Address__c, 
                   Pincode__c, 
                   Red_Score__c, 
                   Status_Update_Date__c, 
                   Status__c 
              FROM Location__c
          ORDER BY Status_Update_Date__c DESC NULLS LAST
             LIMIT 100
        ];
    }

    /**
     * Search locations by Name, Pincode and Address
     * @return List<Location__c> 
     */
    public static List<Location__c> searchLocations(String searchTerm){
        searchTerm += '%';
        return [
            SELECT Id, 
                   Name, 
                   Address__c, 
                   Pincode__c, 
                   Red_Score__c, 
                   Status_Update_Date__c, 
                   Status__c 
              FROM Location__c
             WHERE Name LIKE :searchTerm
                OR Pincode__c LIKE :searchTerm
                OR Address__c LIKE :searchTerm
          ORDER BY Status_Update_Date__c DESC NULLS LAST
        ];
    }

    /**
     * Get a location by its Id
     * @return Location__c
     */
    public static Location__c getLocationById(String locationId){
        List<Location__c> locations = [
            SELECT Id, 
                   Name, 
                   Address__c, 
                   Pincode__c, 
                   Red_Score__c, 
                   Status_Update_Date__c, 
                   Status__c 
              FROM Location__c
             WHERE Id = :locationId
        ];
        if (locations != null && locations.size() > 0){
            return locations[0];
        }
        return null;
    }

    /**
     * Get a Location count for each Status
     * @return Map<String, Integer>
     */
    public static Map<String, Integer> getStatusCount(){
        Map<String, Integer> locationStatusMap = new Map<String, Integer>();
        for(AggregateResult ar: [
            SELECT Status__c, 
                   COUNT(Id) StatusCount 
              FROM Location__c 
          GROUP BY Status__c
        ]) {
            locationStatusMap.put(String.valueOf(ar.get('Status__c')), Integer.valueOf(ar.get('StatusCount')));
        }
        return locationStatusMap;
    }

    public static void updateRedScore(Set<Id> locationIds){
        List<Location__c> locationsToUpdate = new List<Location__c>();
        List<AggregateResult> results = [
            SELECT Location__c,
                   COUNT(Id) RedScore
              FROM Location_Tracing__c
             WHERE Person__r.Health_Status__c = 'Red'
               AND Visit_Date__c = LAST_N_DAYS:10
               AND Location__c IN :locationIds
          GROUP BY Location__c
        ];
        for(AggregateResult res: results){
            String locationId = String.valueOf(res.get('Location__c'));
            Integer redScore = Integer.valueOf(res.get('redScore'));
            String status = getLocationStatus(redScore);
            locationsToUpdate.add(new Location__c(Id=locationId, Red_Score__c=redScore, Status__c=status));
        }
        if(locationsToUpdate != null && locationsToUpdate.size() > 0){
            update locationsToUpdate;
        }
    }

    public static String getLocationStatus(Integer redScore){
        if(redScore == 0){
            return 'Green';
        } else if(redScore <= 5){
            return 'Yellow';
        } else if(redScore <= 10){
            return 'Orange';
        } else {
            return 'Red';
        }
    }

    public static Set<Id> getVisitors(Set<Id> locations){
        List<String> healthStatuses = new List<String>{'Green', 'Yellow'};
        List<Location_Tracing__c> locationTraces = [
            SELECT Person__c 
              FROM Location_Tracing__c
             WHERE Location__c IN :locations
               AND Visit_Date__c = LAST_N_DAYS:10
               AND Person__r.Health_Status__c IN :healthStatuses
        ];
        Set<Id> visitors = new Set<Id>();
        for(Location_Tracing__c lt: locationTraces){
            visitors.add(lt.Person__c);
        }
        return visitors;
    }
}
