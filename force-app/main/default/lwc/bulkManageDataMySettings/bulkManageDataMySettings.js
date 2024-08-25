import { LightningElement, wire, track } from 'lwc';
import getAllowedObjectsAndOperations from '@salesforce/apex/BulkManageDataController.getAllowedObjectsAndOperations';
import userId from "@salesforce/user/Id";

const columns = [
    { label: 'Object Name', fieldName: 'objectName' },
    { label: 'Allowed Operations', fieldName: 'operations' }
];

export default class BulkManageDataMySettings extends LightningElement {
    message; 
    data = [];
    userId = userId;
    columns = columns;

    // Get permissions  
    @wire(getAllowedObjectsAndOperations, { userId: '$userId' })
    wiredData({ data, error }) {
        if (data) {
            // Transform operations array into a comma-separated string
            this.data = data.map(item => {
                return {
                    objectName: item.objectName,
                    operations: item.operations.join(',')
                };
            });
            this.message = 'Data loaded successfully.';
        } else if (error) {
            this.message = 'Failed to load data. Contact your Salesforce Admin.';
            console.error('Apex error:', error);
        }
    }
}