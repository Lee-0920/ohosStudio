import { MaintenceType, MeasureType, CleanType} from 'flow';
export interface WqMaintenanceRow {
  id: string;
  project: string;
  count: string;
  isRunning: boolean;
  status: string;
  result: string;
  maintenceType: MaintenceType;
  params?: MeasureType | CleanType;
}

export interface WqOperationConfigRow {
  id: string;
  category: string;
  name: string;
  value: string;
  value2: string;
  value3: string;
  value4: string;
  unit: string;
  status: string;
  result: string;
  selected: boolean;
  running: boolean;
}

export function copyOperationRow(
  row: WqOperationConfigRow,
  value: string = row.value,
  value2: string = row.value2,
  value3: string = row.value3,
  value4: string = row.value4,
  status: string = row.status,
  result: string = row.result,
  selected: boolean = row.selected,
  running: boolean = row.running
): WqOperationConfigRow {
  return {
    id: row.id,
    category: row.category,
    name: row.name,
    value: value,
    value2: value2,
    value3: value3,
    value4: value4,
    unit: row.unit,
    status: status,
    result: result,
    selected: selected,
    running: running
  };
}

export function updateOperationRowValue(
  rows: WqOperationConfigRow[],
  rowId: string,
  field: string,
  value: string
): WqOperationConfigRow[] {
  return rows.map((row: WqOperationConfigRow) => {
    if (row.id !== rowId) {
      return row;
    }
    if (field === 'value2') {
      return copyOperationRow(row, row.value, value);
    }
    if (field === 'value3') {
      return copyOperationRow(row, row.value, row.value2, value);
    }
    if (field === 'value4') {
      return copyOperationRow(row, row.value, row.value2, row.value3, value);
    }
    if (field === 'result') {
      return copyOperationRow(row, row.value, row.value2, row.value3, row.value4, row.status, value);
    }
    return copyOperationRow(row, value);
  });
}

export function getEmptyRowIndexes(rowCount: number, minRows: number): number[] {
  const rows: number[] = [];
  for (let index = rowCount; index < minRows; index++) {
    rows.push(index);
  }
  return rows;
}
