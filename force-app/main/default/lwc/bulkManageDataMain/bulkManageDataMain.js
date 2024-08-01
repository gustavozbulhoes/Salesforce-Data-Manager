//Based on https://salesforce.stackexchange.com/questions/366322/how-to-copy-data-from-excel-to-lwc-lightning-datatable

import { LightningElement, wire } from 'lwc';
import processRecords from '@salesforce/apex/BulkManageDataController.processRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class bulkManageDataMain extends LightningElement {
  
  data
  // Avoid memory leaks
  _handler
  fields
  columns = []

  chunkSize = 200;
  successes = []
  failures = []

  objectName;
  operationType;
  showSpinner = false;
  finished = false;

  //HANDLE PASTE
  connectedCallback() {
    this._handler = (event) => this.handlePaste(event)
    document.addEventListener('paste', this._handler)
  }
  disconnectedCallback() {
    document.removeEventListener('paste', this._handler)
  }

  handlePaste(event) {
    let csvData = this.csvStringToArray(event.clipboardData.getData('text/plain'))
    this.fields = csvData.splice(0, 1)[0];
    this.columns =  this.fields.map((value) => ({ fieldName: value, label: value }))
    this.data = csvData.map(row => row.reduce((p,v,i) => (p[this.columns[i].fieldName] = v, p), {}))
  }
  csvStringToArray(str) {
    var arr = [];
    var quote = false;
    for (var row = 0, col = 0, c = 0; c < str.length; c++) {
        var cc = str[c], nc = str[c+1];
        arr[row] = arr[row] || [];
        arr[row][col] = arr[row][col] || '';
        if (cc == '"' && quote && nc == '"') { arr[row][col] += cc; ++c; continue; }
        if (cc == '"') { quote = !quote; continue; }
        if (cc == '\t' && !quote) { ++col; continue; }
        if (cc == '\r' && nc == '\n' && !quote) { ++row; col = 0; ++c; continue; }
        if (cc == '\n' && !quote) { ++row; col = 0; continue; }
        if (cc == '\r' && !quote) { ++row; col = 0; continue; }
        arr[row][col] += cc;
    }
    return arr;
  }

  //HANDLE OPERATION
  get objects() {
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
  }

  get disableProcessRecords(){
     return !this.fields || !this.objectName || !this.operationType || !this.data || this.finished || this.chunkSize < 1 || this.chunkSize > 200;
  }

  handleObjectChange(event){
    this.objectName = event.detail.value;
    this.operationType = null;
  }

  handleOperationChange(event){
      this.operationType = event.detail.value;
  }

  async handleProcessRecords() {
    this.showSpinner = true;
    let records = this.data;
    let chunks = this.chunkArray(records, this.chunkSize);
    try {
        let results = await this.processChunks(chunks);
        // Combine results and handle them
        let combinedResult = results.flat();
        this.includeResultInDataTable(combinedResult);
        this.finished = true;
        this.showSpinner = false;
    } catch (error) {
        console.log('ERROR', JSON.stringify(error));
        this.showToast('Error processing records', JSON.stringify(error), 'error', 'dismissable');
        this.showSpinner = false;
    }
  }

  chunkArray(array, size) {
    let result = [];
    for (let i = 0; i < array.length; i += size) {
        result.push(array.slice(i, i + size));
    }
    return result;
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
    this.fields = this.getAllProperties(result);
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

  getAllProperties(objects) {
    let properties = new Set();
    objects.forEach(obj => {Object.keys(obj).forEach(key => {
            if (key !== 'Id') {
                properties.add(key);
            }
        });
    });
    let result = Array.from(properties);
    result.push('Id'); // Add 'Id' at the end
    return result;
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