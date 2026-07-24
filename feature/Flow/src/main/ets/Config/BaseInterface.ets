import { ParameterItem } from './BaseEnum';

export interface Param {
  readonly paramName: ParameterItem
  value?: number | string | SelectOption[]
  select?: number
  readonly unit?: string
}

export interface Type {
  readonly name: string,
  params: Param[]
}

export interface SetConfig {
  type: Type[]
}