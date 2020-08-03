/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 03/08/2020
 */

trigger LeadAssignToQueue on Lead (before insert, before update) {
    Group hotQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Hot_Queue'];
    for(Lead thisLead : Trigger.new) {
        if(thisLead.Company.contains('Apex') && thisLead.Rating == 'Hot') {
            thisLead.OwnerId = hotQueue.Id;
        }
    }
}