import communication from 'libcommunication.so';

export class Dncp {
  createPlugin(): void { communication.dncp_createPlugin(); }
  doProxy(): void { communication.dncp_doProxy(); }
  addSlaveNode(nodeId: number): void { communication.dncp_addSlaveNode(nodeId); }
  initDncpStack(
    serialPort: string,
    bridgeMode: boolean,
    bridgeIP: string,
    onStatusChanged: (pollingAddr: number, status: boolean) => void
  ): void {
    // 注意：这里调用的 native 方法名需与 napi_property_descriptor 中注册的名称一致
    return communication.dncp_initDncpStack(
      serialPort,
      bridgeMode,
      bridgeIP,
      onStatusChanged
    );
  }
  startSignalUpload(): void { communication.dncp_startSignalUpload(); }
  stopSignalUpload(): void { communication.dncp_stopSignalUpload(); }
  isConnected(addr: number): boolean { return communication.dncp_isConnected(addr); }
}

export default new Dncp();