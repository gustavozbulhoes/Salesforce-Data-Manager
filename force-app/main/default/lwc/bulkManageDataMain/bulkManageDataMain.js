//Based on https://salesforce.stackexchange.com/questions/366322/how-to-copy-data-from-excel-to-lwc-lightning-datatable

import { LightningElement, wire, track } from 'lwc';
import processRecords from '@salesforce/apex/BulkManageDataController.processRecords';
import getAllowedObjectsAndOperations from '@salesforce/apex/BulkManageDataController.getAllowedObjectsAndOperations';
import userId from "@salesforce/user/Id";
import {csvStringToArray,chunkArray} from './utils.js'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class bulkManageDataMain extends LightningElement {
  
  data
  // Avoid memory leaks
  _handler
  fields
  columns = []

  userId = userId

  chunkSize = 200;
  successes = []
  failures = []

  objectName;
  operationType;
  showSpinner = false;
  finished = false;

  @track objectOptions = [];
  @track operationOptions = [];
  allowedOperationsMap = new Map();


  //HANDLE PASTE
  connectedCallback() {
    this._handler = (event) => this.handlePaste(event)
    document.addEventListener('paste', this._handler)
  }
  disconnectedCallback() {
    document.removeEventListener('paste', this._handler)
  }

  handlePaste(event) {
    let csvData = csvStringToArray(event.clipboardData.getData('text/plain'))
    this.fields = csvData.splice(0, 1)[0];
    this.columns =  this.fields.map((value) => ({ fieldName: value, label: value }))
    this.data = csvData.map(row => row.reduce((p,v,i) => (p[this.columns[i].fieldName] = v, p), {}))
  }

  //HANDLE OPERATION

  //get permissions  
  @wire(getAllowedObjectsAndOperations, {userId: '$userId'})
  wiredData({ data, error }) {
      if (data) {
          // Ensure data is iterable and each item has defined operations
          try {
              this.objectOptions = data.map(item => ({
                  label: item.objectName,
                  value: item.objectName
              }));
              data.forEach(item => {
                  if (item.operations) {
                      this.allowedOperationsMap.set(item.objectName, Array.from(item.operations));
                  } else {
                      console.warn(`No operations defined for ${item.objectName}`);
                  }
              });
          } catch (err) {
              console.error('Error processing data:', err);
          }
      } else if (error) {
          console.error('Apex error:', error);
      }
  }

  /*get objects() {
    return [
        { label: 'Opportunity', value: 'Opportunity' },
        { label: 'Account', value: 'Account' },
    ];
  }

  get operations() {
      return [
          { label: 'Insert', value: 'Insert' },
          { label: 'Update', value: 'Update' },
      ];
  }*/

  get processRecordsButtonLabel() {
    return this.operationType || '';
  }
  
  get disableProcessRecords(){
     return !this.fields || !this.objectName || !this.operationType || !this.data || this.finished || this.chunkSize < 1 || this.chunkSize > 200;
  }

  handleObjectChange(event){
    this.objectName = event.detail.value;
    this.operationType = null;
    this.operationOptions = this.allowedOperationsMap.get(this.objectName).map(op => ({
      label: op,
      value: op
  }));
  }

  handleOperationChange(event){
      this.operationType = event.detail.value;
  }

  async handleProcessRecords() {
    this.showSpinner = true;
    let chunks = chunkArray(this.data, this.chunkSize);
    try {
        let results = await this.processChunks(chunks);
        this.includeResultInDataTable(results.flat()); // Combine results and handle them
        this.finished = true;
        this.showSpinner = false;
    } catch (error) {
        console.log('ERROR', JSON.stringify(error));
        this.showToast('Error processing records', JSON.stringify(error), 'error', 'dismissable');
        this.showSpinner = false;
    }
  }

  async processChunks(chunks) {
    let results = [];
    for (let chunk of chunks) {
        chunk.forEach(record => { record.sobjectType = this.objectName });
        let result = await processRecords({ objects: chunk, operationType: this.operationType, fields: this.fields })
        results.push(result.records);
        this.successes.push(...result.successes);
        this.failures.push(...result.failures);
    }
    return results;
  }

  changeChunkSizeHandler(event){
    this.chunkSize = event.target.value;
  }

  includeResultInDataTable(result){
    if(!this.fields.includes('Id')){
      this.fields.push('Id');
    }
    this.fields.push('_result');
    this.columns =  this.fields.map((value) => ({ fieldName: value, label: value }))
    this.data = result;

    let errorIndex = 0;
    this.data.forEach((value) => {
        if(this.successes.includes(value.Id)){
            value['_result'] = 'Success';
        } else {
            value['_result'] = 'Error: ' + this.failures[errorIndex];
            errorIndex++;
        }
    } );
  }

  copyToClipboard() {
    let dataString = this.fields.join('\t') + '\n';
    dataString += this.data.map(row => 
        this.columns.map(col => row[col.fieldName]).join('\t')
    ).join('\n');

    // Use the Clipboard API to write the data to the clipboard
    navigator.clipboard.writeText(dataString).then(() => {
        this.showToast('Success', 'Data copied to clipboard!', 'success', 'dismissable');
    }).catch(err => {
        console.error('Failed to copy: ', err);
        this.showToast('Error', 'Failed to copy data to clipboard', 'error', 'dismissable');
    });
  }

  refresh(){
    this.data = null;
    this.columns = [];
    this.finished = false;
    this.objectName = null;
    this.operationType = null;
    this.successes = [];
    this.failures = [];
  }

  showToast(title, message, variant, mode) {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode
    });
    this.dispatchEvent(evt);
  }
}