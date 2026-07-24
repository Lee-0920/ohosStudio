import {
  EffectiveMode,
  MeasurementMode,
  ParameterItem,
  RangeMode,
  RangeOne,
  Switch,
  TypeItem,
  Unit,
  INSTRUMENTSTATUS,
  TransmissionRate,
  CheckDigit,
  WaterSamplingMode,
  RelayMode,
  TRANSMISSIONPROTOCOLMode,
  MODBUSPROTOCOLMODE
} from './BaseEnum';
import { SetConfig } from './BaseInterface';

export let MeasurementScheduleConfig: SetConfig = {
  type: [
    {
      name: TypeItem.WATERMEASURE,
      params: [
        {
          paramName: ParameterItem.MEASUREMENTMODE,
          value: [{ value: MeasurementMode.EXTERNALTRIGGER },
            { value: MeasurementMode.PERIODMEASUREMENT },
            { value: MeasurementMode.PERIODICMEASUREMENT },
            { value: MeasurementMode.CONTINUOUSMEASUREMENT }],
          select: 0
        },
        {
          paramName: ParameterItem.INTERVALPERIOD,
          value: 2,
          unit: Unit.HOUR
        },
        {
          paramName: ParameterItem.TIMEPOINTSET,
          value: '0,1,2',
        }
      ]
    },
    {
      name: TypeItem.CALIBRATION,
      params: [
        {
          paramName: ParameterItem.MEASUREMENTMODE,
          value: [{ value: MeasurementMode.EXTERNALTRIGGER },
            { value: MeasurementMode.PERIODMEASUREMENT },
            { value: MeasurementMode.PERIODICMEASUREMENT }],
          select: 0
        },
        {
          paramName: ParameterItem.INTERVALPERIOD,
          value: 2,
          unit: Unit.HOUR
        },
        {
          paramName: ParameterItem.TIMEPOINTSET
        },
        {
          paramName: ParameterItem.INTERVALTIME,
          value: 7,
          unit: Unit.DAY
        },
      ]
    },
    {
      name: TypeItem.TIMECALIBRATION,
      params: [
        {
          paramName: ParameterItem.AUTOMATICVERIFICATION,
          value: [{ value: Switch.OPEN }, { value: Switch.CLOSE }],
          select: 0
        },
        {
          paramName: ParameterItem.INTERVALPERIOD,
          value: 168,
          unit: Unit.HOUR
        }
      ]
    },
    {
      name: TypeItem.RANGECALIBRATION,
      params: [
        {
          paramName: ParameterItem.AUTOMATICVERIFICATION,
          value: [{ value: Switch.OPEN }, { value: Switch.CLOSE }],
          select: 0
        },
        {
          paramName: ParameterItem.INTERVALPERIOD,
          value: 168,
          unit: Unit.HOUR
        }
      ]
    },
    {
      name: TypeItem.STANDARDMEASURE,
      params: [
        {
          paramName: ParameterItem.MEASUREMENTMODE,
          value: [{ value: MeasurementMode.EXTERNALTRIGGER },
            { value: MeasurementMode.PERIODMEASUREMENT },
            { value: MeasurementMode.PERIODICMEASUREMENT }],
          select: 0
        },
        {
          paramName: ParameterItem.INTERVALPERIOD,
          value: 168,
          unit: Unit.HOUR
        },
        {
          paramName: ParameterItem.TIMEPOINTSET
        },
        {
          paramName: ParameterItem.INTERVALTIME,
          value: 7,
          unit: Unit.DAY
        }
      ]
    },
    {
      name: TypeItem.ZEROPOINTVERIFICATIONSOLUTION,
      params: [
        {
          paramName: ParameterItem.MEASUREMENTMODE,
          value: [
            { value: MeasurementMode.EXTERNALTRIGGER },
            { value: MeasurementMode.PERIODMEASUREMENT },
            { value: MeasurementMode.PERIODICMEASUREMENT }
          ]
        },
        {
          paramName: ParameterItem.INTERVALPERIOD,
          value: 168,
          unit: Unit.HOUR
        },
        {
          paramName: ParameterItem.TIMEPOINTSET,
          value: ''
        },
        {
          paramName: ParameterItem.INTERVALTIME,
          value: 1,
          unit: Unit.DAY
        }
      ]
    },
    {
      name: TypeItem.SPIKEDRECOVERY,
      params: [
        {
          paramName: ParameterItem.AUTOMATICMARKUP,
          value: [{ value: Switch.OPEN }, { value: Switch.CLOSE }],
          select: 0
        },
        {
          paramName: ParameterItem.INTERVALPERIOD,
          value: 168,
          unit: Unit.HOUR
        }
      ]
    },
    {
      name: TypeItem.PARALLELMEASUREMENT,
      params: [
        {
          paramName: ParameterItem.AUTOMATICPARALLELISM,
          value: [{ value: Switch.OPEN }, { value: Switch.CLOSE }],
          select: 0
        },
        {
          paramName: ParameterItem.INTERVALPERIOD,
          value: 168,
          unit: Unit.HOUR
        }
      ]
    },
    {
      name: TypeItem.DEEPCLEANING,
      params: [
        {
          paramName: ParameterItem.AUTOMATICCLEANING,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE },
          ]
        },
        {
          paramName: ParameterItem.INTERVALPERIOD,
          value: 168,
          unit: Unit.HOUR
        }
      ]
    },
    {
      name: TypeItem.EXACTSTART,
      params: [
        {
          paramName: ParameterItem.DETERMINEEXTENTIONTIME,
          value: 5,
          unit: Unit.SECOND
        }
      ]
    },
  ]
}

export let MeasurementParameterConfig: SetConfig = {
  type: [
    {
      name: TypeItem.RANGESELECTION,
      params: [
        {
          paramName: ParameterItem.CURRENTRANGE,
          value: [
            { value: RangeMode.RANGEONE },
            { value: RangeMode.RANGETWO },
            { value: RangeMode.RANGETHREE },
          ]
        },
        {
          paramName: ParameterItem.CALIBRATIONRANGE,
          value: [
            { value: RangeMode.RANGEONE },
            { value: RangeMode.RANGETWO },
            { value: RangeMode.RANGETHREE },
          ]
        },
        {
          paramName: ParameterItem.ZEROPOINTVERIFICATIONRANGE,
          value: [
            { value: RangeMode.RANGEONE },
            { value: RangeMode.RANGETWO },
            { value: RangeMode.RANGETHREE },
          ]
        },
        {
          paramName: ParameterItem.SPECIFICATIONVERIFICATIONRANGE,
          value: [
            { value: RangeMode.RANGEONE },
            { value: RangeMode.RANGETWO },
            { value: RangeMode.RANGETHREE },
          ]
        },
        {
          paramName: ParameterItem.RANGEONE,
          value: [
            { value: RangeOne.SELECTIONONE },
            { value: RangeOne.SELECTIONTWO },
            { value: RangeOne.SELECTIONTHREE },
            { value: RangeOne.SELECTIONFOUR },
          ]
        },
        {
          paramName: ParameterItem.RANGETWO,
          value: [
            { value: RangeOne.SELECTIONONE },
            { value: RangeOne.SELECTIONTWO },
            { value: RangeOne.SELECTIONTHREE },
            { value: RangeOne.SELECTIONFOUR },
          ]
        },
        {
          paramName: ParameterItem.RANGETHREE,
          value: [
            { value: RangeOne.SELECTIONONE },
            { value: RangeOne.SELECTIONTWO },
            { value: RangeOne.SELECTIONTHREE },
            { value: RangeOne.SELECTIONFOUR },
          ]
        },
        {
          paramName: ParameterItem.AUTOMATICRANGESWITCHING,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE },
          ]
        },
        {
          paramName: ParameterItem.EFFECTIVEMODEAFTERSWITCHING,
          value: [
            { value: EffectiveMode.IMMEDIATELY },
            { value: EffectiveMode.NEXT },
          ]
        }
      ]
    },
    {
      name: TypeItem.CURRENTRANGEINFO,
      params: [
        {
          paramName: ParameterItem.SLANTDISTANCE,
          value: 0.07,
          unit: Unit.num3
        },
        {
          paramName: ParameterItem.INTERCEPT,
          value: -3.86,
          unit: Unit.num4
        },
        {
          paramName: ParameterItem.CALIBRATIONTIME,
          value: new Date().toString()
        }
      ]
    },
    {
      name: TypeItem.CALIBRATIONRANGEINFO,
      params: [
        {
          paramName: ParameterItem.ZEROCALIBRATIONLIQUIDCONCENTRATION,
          value: 0,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.SPANCALIBRATIONLIQUIDCONCENTRATION,
          value: 25,
          unit: Unit.MG
        }
      ]
    },
    {
      name: TypeItem.INTELLIGENTDETERMINATION,
      params: [
        {
          paramName: ParameterItem.CALIBRATIONQUALIFICATION,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.CALIBRATIONOUTPUTTWOPOINTRESULT,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.CALIBRATIONUPDATEALLSTANDARDCURVES,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.CALIBRATIONLABELOUTPUT,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        }
      ]
    },
    {
      name: TypeItem.DISCHARGE,
      params: [
        {
          paramName: ParameterItem.DECOMPOSITIONTEMPERATURE,
          value: 40,
          unit: Unit.tem
        },
        {
          paramName: ParameterItem.REDUCTIONOFTIME,
          value: 60,
          unit: Unit.SECOND
        }
      ]
    },
    {
      name: TypeItem.REACTION,
      params: [
        {
          paramName: ParameterItem.REACTIONTEMPERATURE,
          value: 45,
          unit: Unit.tem
        },
        {
          paramName: ParameterItem.REACTIONTIME,
          value: 90,
          unit: Unit.SECOND
        }
      ]
    },
    {
      name: TypeItem.VERIFICATION,
      params: [
        {
          paramName: ParameterItem.CHECKCONCENTRATION,
          value: 600,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.CHECKDEVIATIONLIMIT,
          value: 10,
          unit: Unit.PERCENT
        },
        {
          paramName: ParameterItem.CHECKREPORTING,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.AUTOCALIBRATIONONOVERFLOW,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        }
      ]
    },
    {
      name: TypeItem.CORRECTION,
      params: [
        {
          paramName: ParameterItem.NEGATIVECORRECTION,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.SLOPECORRECTION,
          value: 1
        },
        {
          paramName: ParameterItem.INTERCEPTCORRECTION,
          value: 0
        }
      ]
    },
    {
      name: TypeItem.PREMEARSUREMENTCLEAN,
      params: [
        {
          paramName: ParameterItem.ZEROCALIBRATIONLIQUID,
          value: 0,
          unit: Unit.ML
        }
      ]
    },
    {
      name: TypeItem.CLEANMODE,
      params: [
        {
          paramName: ParameterItem.ANTIFOULINGMODE,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.TAPWATERMODE,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
      ]
    },
    {
      name: TypeItem.PIPELINE,
      params: [
        {
          paramName: ParameterItem.WATER_SAMPLE_TUBE_EXTENDED_VOLUME,
          value: 0,
          unit: Unit.ML
        },
        {
          paramName: ParameterItem.WATER_SAMPLE_UPDATEVOLUME,
          value: 2,
          unit: Unit.ML
        }
      ]
    },
    {
      name: TypeItem.REAGENT,
      params: [
        {
          paramName: ParameterItem.REAGENTUPDATE,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        }
      ]
    }
  ]
}

export let ExternalInterfaceConfig: SetConfig = {
  type: [
    {
      name: TypeItem.INSTRUMENTSTATUS,
      params: [
        {
          paramName: ParameterItem.STATUS,
          value: [
            { value: INSTRUMENTSTATUS.RUN },
            { value: INSTRUMENTSTATUS.OFFLINE },
            { value: INSTRUMENTSTATUS.MAINTENANCE },
            { value: INSTRUMENTSTATUS.MALFUNCTION },
            { value: INSTRUMENTSTATUS.CALIBRATION },
            { value: INSTRUMENTSTATUS.DEBUGGING },
          ]
        }
      ]
    },
    {
      name: TypeItem.WATERSAMPLEOVERSTANDARDSETTING,
      params: [
        {
          paramName: ParameterItem.ALARM,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.EXCEEDINGTHEUPPERLIMIT,
          value: 20000,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.EXCEEDINGTHELOWERLIMIT,
          value: 0,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.STARTTHEVERIFICATION,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        }
      ]
    },
    {
      name: TypeItem.MODBUS,
      params: [
        {
          paramName: ParameterItem.POSTALADDRESS,
          value: 1
        }
      ]
    },
    {
      name: TypeItem.RS485,
      params: [
        {
          paramName: ParameterItem.TRANSMISSIONRATE,
          value: [
            { value: TransmissionRate.RATE1 },
            { value: TransmissionRate.RATE2 },
            { value: TransmissionRate.RATE3 },
            { value: TransmissionRate.RATE4 },
            { value: TransmissionRate.RATE5 }
          ],
          unit: Unit.BPS
        },
        {
          paramName: ParameterItem.CHECKDIGIT,
          value: [
            { value: CheckDigit.EMPTY },
            { value: CheckDigit.PARITYCHECK1 },
            { value: CheckDigit.PARITYCHECK2 }
          ]
        }
      ]
    },
    {
      name: TypeItem.RS232,
      params: [
        {
          paramName: ParameterItem.TRANSMISSIONRATE,
          value: [
            { value: TransmissionRate.RATE1 },
            { value: TransmissionRate.RATE2 },
            { value: TransmissionRate.RATE3 },
            { value: TransmissionRate.RATE4 },
            { value: TransmissionRate.RATE5 }
          ],
          unit: Unit.BPS
        },
        {
          paramName: ParameterItem.CHECKDIGIT,
          value: [
            { value: CheckDigit.EMPTY },
            { value: CheckDigit.PARITYCHECK1 },
            { value: CheckDigit.PARITYCHECK2 }
          ]
        }
      ]
    },
    {
      name: TypeItem.WATERSAMPLE420,
      params: [
        {
          paramName: ParameterItem.CORRESPONDINGCONCENTRATION4,
          value: 0,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.CORRESPONDINGCONCENTRATION20,
          value: 200,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.CALIBRATIONCOEFFICIENT,
          value: 1
        }
      ]
    },
    {
      name: TypeItem.WATERSAMPLINGSETUP,
      params: [
        {
          paramName: ParameterItem.WATERSAMPLINGMODE,
          value: [
            { value: WaterSamplingMode.EXTERNALTRIGGER },
            { value: WaterSamplingMode.PRECOLLECTINGWATER },
            { value: WaterSamplingMode.UNTILSAMPLING },
            { value: WaterSamplingMode.UNTILMEASUREMENT }
          ]
        },
        {
          paramName: ParameterItem.PREWATERSAMPLINGTIME,
          value: 20,
          unit: Unit.SECOND
        },
        {
          paramName: ParameterItem.PRESILENCEPERIOD,
          value: 20,
          unit: Unit.SECOND
        }
      ]
    },
    {
      name: TypeItem.MULTIFUNCTIONALRELAY,
      params: [
        {
          paramName: ParameterItem.RELAY1,
          value: [
            { value: RelayMode.UPPERLIMIT },
            { value: RelayMode.LOWERLIMIT },
            { value: RelayMode.MEASUREMENTINDICATION },
            { value: RelayMode.CALIBRATIONINDICATION },
            { value: RelayMode.CLEANINGINSTRUCTIONS },
            { value: RelayMode.WATERSAMPLINGINDICATION },
            { value: RelayMode.STANDARDSAMPLEVERIFICATION },
            { value: RelayMode.ALARMINDICATION }
          ],
          select: 5
        },
        {
          paramName: ParameterItem.RELAY2,
          value: [
            { value: RelayMode.UPPERLIMIT },
            { value: RelayMode.LOWERLIMIT },
            { value: RelayMode.MEASUREMENTINDICATION },
            { value: RelayMode.CALIBRATIONINDICATION },
            { value: RelayMode.CLEANINGINSTRUCTIONS },
            { value: RelayMode.WATERSAMPLINGINDICATION },
            { value: RelayMode.STANDARDSAMPLEVERIFICATION },
            { value: RelayMode.ALARMINDICATION }
          ],
          select: 0
        }
      ]
    }
  ]
}

export let SystemParametersConfig: SetConfig = {
  type: [
    {
      name: TypeItem.INSTRUMENTPROTECTION,
      params: [
        {
          paramName: ParameterItem.REMINDERREPLACEMENT,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.ABNORMALRETESTING,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        }
      ]
    },
    {
      name: TypeItem.SPECIALPARAMETERS,
      params: [
        {
          paramName: ParameterItem.OPENVALUATION,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.MARKINGS,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.LEAKAGEDETECTION,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.DRYCONTACTTRIGGERMEASUREMENT,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.DETAILEDRECORD,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.REAGENTMANAGEMENT,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        }
      ]
    },
    {
      name: TypeItem.DATAREPORTING,
      params: [
        {
          paramName: ParameterItem.TRANSMISSIONPROTOCOL,
          value: [
            { value: TRANSMISSIONPROTOCOLMode.MODBUS },
            { value: TRANSMISSIONPROTOCOLMode.CCEP },
            { value: TRANSMISSIONPROTOCOLMode.HJ2017 },
            { value: TRANSMISSIONPROTOCOLMode.HJ2005 },
            { value: TRANSMISSIONPROTOCOLMode.HJ2025 }
          ]
        }
      ]
    },
    {
      name: TypeItem.MODBUSCOMMUNICATION,
      params: [
        {
          paramName: ParameterItem.MODBUSPROTOCOL,
          value: [
            { value: MODBUSPROTOCOLMODE.LS1 },
            { value: MODBUSPROTOCOLMODE.JS },
            { value: MODBUSPROTOCOLMODE.SZBA },
            { value: MODBUSPROTOCOLMODE.DYNAMICCONTROL },
            { value: MODBUSPROTOCOLMODE.GZ },
            { value: MODBUSPROTOCOLMODE.SC },
            { value: MODBUSPROTOCOLMODE.SURFACEWATER },
            { value: MODBUSPROTOCOLMODE.LS2 },
            { value: MODBUSPROTOCOLMODE.XIAN },
            { value: MODBUSPROTOCOLMODE.JX },
            { value: MODBUSPROTOCOLMODE.YC },
            { value: MODBUSPROTOCOLMODE.LS4 },
          ],
          select: 11
        }
      ]
    },
    {
      name: TypeItem.DISPLAYSCREEN,
      params: [
        {
          paramName: ParameterItem.SCREENSAVER,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.AUTOMATICDARKSCREENTIME,
          value: 300,
          unit: Unit.SECOND
        },
        {
          paramName: ParameterItem.AUTOMATICSCREENTURNINGOFFTIME,
          value: 600,
          unit: Unit.SECOND
        }
      ]
    },
    {
      name: TypeItem.RANGESETTING,
      params: [
        {
          paramName: ParameterItem.ALTERNATIVEMEASUREMENTRANGE1,
          value: 100,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.ALTERNATIVEMEASUREMENTRANGE2,
          value: 200,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.ALTERNATIVEMEASUREMENTRANGE3,
          value: 500,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.ALTERNATIVEMEASUREMENTRANGE4,
          value: 1000,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.ALTERNATIVEMEASUREMENTRANGE5,
          value: 5000,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.ALTERNATIVEMEASUREMENTRANGE6,
          value: 10000,
          unit: Unit.MG
        },
        {
          paramName: ParameterItem.ALTERNATIVEMEASUREMENTRANGE7,
          value: 20000,
          unit: Unit.MG
        }
      ]
    },
    {
      name: TypeItem.REMOTEFILE,
      params: [
        {
          paramName: ParameterItem.FUNCTIONSWITCH,
          value: [
            { value: Switch.OPEN },
            { value: Switch.CLOSE }
          ]
        },
        {
          paramName: ParameterItem.IPADDRESS,
          value: '192.168.1.18'
        }
      ]
    }
  ]
}