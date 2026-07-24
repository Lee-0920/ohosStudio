import communication from 'libcommunication.so';

export class Dncp {
  createPlugin(): void { communication.dncp_createPlugin(); }
  doProxy(): void { communication.dncp_doProxy(); }
  addSlaveNode(nodeId: number): void { communication.dncp_addSlaveNode(nodeId); }
  initDncpStack(serialPort: string, bridgeMode: boolean, bridgeIP: string): void { communication.dncp_initDncpStack(serialPort, bridgeMode, bridgeIP); }
  startSignalUpload(): void { communication.dncp_startSignalUpload(); }
  stopSignalUpload(): void { communication.dncp_stopSignalUpload(); }
}

export default new Dncp();