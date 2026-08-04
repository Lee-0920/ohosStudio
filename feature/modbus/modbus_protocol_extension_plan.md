# Modbus 多协议扩展实施计划

## 一、背景与目标

`feature/modbus` 目前已实现 LS4.0（对应 `feature/Lua/Modbus/Labsun40.ls`），并预留了 `JS`、`SZBA`、`地表水1.0` 的占位协议表。`feature/Lua/Modbus` 下还有 Labsun10、Labsun20、DBS、SC、XN、GZ、JX、XiAn、YC 等协议脚本。

目标：在不影响 LS4.0 的前提下，为上述所有协议提供真实的 `ProtocolTable` 映射，并补齐输入寄存器（FC=04）支持，使设置页中 12 个 Modbus 协议选项都能真正生效。

## 二、关键设计决策

1. **统一内部地址空间**：继续以 `Registers.ets` 中的 LS4.0 地址作为内部地址空间。每种协议只负责把外部地址映射到内部地址，业务处理逻辑保持不变。
2. **通用偏移基类**：提取 `OffsetProtocolTable`，用 `inputBase` / `holdingBase` 覆盖需要 30001/40001、30200/40100、0x1000 等基址的协议。
3. **恒等映射协议**：LS2.0、SZBA、SC、XN、YC 等外部地址与内部 LS4.0 地址一致，直接复用 `Ls40ProtocolTable` 的映射逻辑，仅替换名称。
4. **FC=04 支持**：JS、GZ、JX、XiAn、Labsun10 使用输入寄存器，需要在 RTU/TCP 解析层新增 FC=04 分支，并在 TCP PDU 构建方法中取消硬编码的 0x03。
5. **DataStore 修复**：`DataStore` 写权限校验应直接查 `REGISTERS`，避免偏移协议表对内部地址二次转换。

## 三、需修改的文件

| 文件 | 修改内容 |
|---|---|
| `feature/modbus/src/main/ets/model/ProtocolTable.ets` | 扩展 `ModbusProtocolType`；新增 `OffsetProtocolTable`；实现全部协议表并注册 |
| `feature/modbus/src/main/ets/model/DataStore.ets` | 内部地址查询改为直接查 `REGISTERS` |
| `feature/modbus/src/main/ets/model/ModbusRTU.ets` | 新增 FC=04 解析与分发；`getRegisterName` 增加功能码参数 |
| `feature/modbus/src/main/ets/model/ModbusTCP.ets` | 新增 FC=04 解析；所有读响应 PDU 构建方法支持动态功能码 |
| `feature/modbus/Index.d.ts` | 同步类型声明 |
| `feature/modbus/src/main/ets/index.ets` | 导出新增协议表类 |
| `products/entry/src/main/ets/pages/SettingPage.ets` | 更新 `modbusProtocolModeToTableName`，将各模式映射到真实协议表名 |

## 四、协议表映射规则

协议名使用设置页 `MODBUSPROTOCOLMODE` 枚举值：

| 协议名 | Lua 文件 | 映射方式 | inputBase | holdingBase | 说明 |
|---|---|---|---|---|---|
| LS4.0 | Labsun40.ls | 恒等 | 0 | 0 | 保持现有行为 |
| LS1.0 | Labsun10.ls | 偏移 | 0 | 256 | FC=04 读 0-255；FC=03 读 256-511 |
| LS2.0 | Labsun20.ls | 恒等 | 0 | 0 | 仅保持寄存器 |
| JS | JS.ls | 偏移 | 30001 | 40001 | FC=04 / FC=03 双空间 |
| 地表水1.0 | DBS.ls | 偏移 | 0 | 0x1000 | 仅保持寄存器 |
| SZBA | SZBA.ls | 恒等 | 0 | 0 | 仅保持寄存器 |
| SC | SC.ls | 恒等 | 0 | 0 | 仅保持寄存器 |
| 西宁动态管控 | XN.ls | 恒等 | 0 | 0 | 仅保持寄存器 |
| GZ | GZ.ls | 偏移 | 30001 | 40001 | FC=04 / FC=03 双空间 |
| JX | JX.ls | 偏移 | 30001 | 40001 | FC=04 / FC=03 双空间 |
| XiAn | XiAn.ls | 偏移 | 30200 | 40100 | FC=04 / FC=03 双空间 |
| YC | YC.ls | 恒等 | 0 | 0 | 仅保持寄存器 |

`ProtocolTableRegistry.get(name)` 对未知名称自动回退到 `LS4.0`。

## 五、RTU/TCP 改动要点

### 5.1 RTU
- `parseRequest` 中识别 `functionCode === 0x04`，报文解析逻辑与 0x03 相同。
- `processRequest` 中将 0x04 与 0x03 一起路由到 `handleRead`。
- `handleRead` 已使用 `request.functionCode` 构建响应，回显功能码自动正确。

### 5.2 TCP
- `parseRequest` 中识别 0x04，解析逻辑与 0x03 相同。
- `processRequest` 中将 0x04 路由到 `handleRead`。
- 所有读 PDU 构建方法（`buildUint16PDU`、`buildFloat32PDU`、`buildTimePDU`、`buildStringPDU`、`buildFloat32ArrayPDU`、`buildUINT32PDU`、`buildSEUINT32PDU`）增加 `functionCode` 参数，替换硬编码的 `pdu[0] = 0x03`。
- 便捷响应方法（`responseUint16`、`responseFloat32` 等）同步透传 `functionCode`。

## 六、SettingPage 映射更新

将 `modbusProtocolModeToTableName` 中的回退逻辑更新为：

```typescript
private modbusProtocolModeToTableName(modeValue: string): string {
  const map: Record<string, string> = {
    'LS1.0': 'LS1.0',
    'JS': 'JS',
    'SZBA': 'SZBA',
    '西宁动态管控': '西宁动态管控',
    'GZ': 'GZ',
    'SC': 'SC',
    '地表水1.0': '地表水1.0',
    'LS2.0': 'LS2.0',
    'XiAn': 'XiAn',
    'JX': 'JX',
    'YC': 'YC',
    'LS4.0': 'LS4.0'
  };
  return map[modeValue] ?? 'LS4.0';
}
```

`protocolTableNameToModbusProtocolMode` 同步补充新增协议的双向映射。

## 七、风险与应对

| 风险 | 应对 |
|---|---|
| 影响 LS4.0 | `Ls40ProtocolTable` 保持恒等映射；新增可选 `functionCode` 参数不影响旧行为。 |
| DataStore 内部地址被二次偏移 | 改为直接查 `REGISTERS`。 |
| TCP 读响应功能码错误 | 所有读 PDU 构建方法透传实际功能码。 |
| DBS 输入寄存器 0-0xFFF 未模拟空块 | DBS 实际使用 FC=03，风险可接受。 |
| 协议名与 UI 枚举不一致 | 使用 `MODBUSPROTOCOLMODE` 中的确切值。 |

## 八、验证方案

1. **协议表单元测试**：验证各协议的 `toInternalAddress` / `toExternalAddress` 双向映射。
2. **注册中心回退测试**：未知名称回退到 LS4.0。
3. **FC=04 集成测试**：构造 RTU/TCP 的 FC=04 报文，验证响应功能码为 0x04。
4. **UI 验证**：设置页选择各协议后，重启应用能正确恢复；恢复默认回到 LS4.0。

## 九、实施顺序

1. `ProtocolTable.ets` + `DataStore.ets` ✅
2. `ModbusRTU.ets` ✅
3. `ModbusTCP.ets` ✅
4. `Index.d.ts` + `index.ets` ✅
5. `SettingPage.ets` ✅
6. 单元测试与联调（待补充）
