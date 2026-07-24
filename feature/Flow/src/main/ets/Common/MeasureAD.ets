import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;

/**
 * @brief 吸光度计算类
 */
export class MeasureAD {
  blankReference: number = 0;
  blankMeasure: number = 0;
  initReference: number = 0;
  initMeasure: number = 0;
  finalReference: number = 0;
  finalMeasure: number = 0;

  constructor() {}

  /**
   * 计算相对吸光度
   * @returns 相对吸光度值（乘以1000）
   */
  CalculateRelAbsorbance(): number {
    let abs = 0;
    // 注意：config需要根据实际项目的配置模块进行适配
    // const turbidityDeduction = config.measureParam.algorithm.turbidityDeduction;
    // const tubFactor = config.measureParam.tubFactor;
    const turbidityDeduction = false; // 默认值，需根据实际配置调整
    const tubFactor = 1; // 默认值，需根据实际配置调整

    //跳流程调试，不考虑暗电流导致的负值
    if (this.blankReference <= 0 || this.blankMeasure <= 0 ||
        // this.initReference <= 0 || this.initMeasure <= 0 ||
        this.finalReference <= 0 || this.finalMeasure <= 0) {
      hilog.info(DOMAIN, 'MeasureAD', 'MeasureAD return 0');
      return 0;
    }

    const final = Math.log10(this.finalReference / this.finalMeasure);
    const init = Math.log10(this.initReference / this.initMeasure);
    const blank = Math.log10(this.blankReference / this.blankMeasure);
    hilog.debug(DOMAIN, 'MeasureAD', `反应值 = ${final}，初始值 = ${init}，空白值 = ${blank}`);

    if (turbidityDeduction) {
      abs = Math.log10(this.finalReference / this.finalMeasure)
        - (Math.log10(this.initReference / this.initMeasure) - Math.log10(this.blankReference / this.blankMeasure)) * tubFactor
        - Math.log10(this.blankReference / this.blankMeasure);
    } else {
      abs = Math.log10(this.finalReference / this.finalMeasure) - Math.log10(this.blankReference / this.blankMeasure);
    }

    return abs * 1000;
  }

  /**
   * 计算绝对吸光度
   * @returns 绝对吸光度值（乘以1000）
   */
  CalculateAbsAbsorbance(): number {
    let abs = 0;
    if (this.finalReference <= 0 || this.finalMeasure <= 0) {
      hilog.info(DOMAIN, 'MeasureAD', 'MeasureAD CalculateAbsAbsorbance return 0');
      return 0;
    }

    abs = Math.log10(this.finalReference / this.finalMeasure);

    return abs * 1000;
  }

  /**
   * 计算初始吸光度
   * @returns 初始吸光度值（乘以1000）
   */
  CalculateInitAbsorbance(): number {
    let abs = 0;
    if (this.initReference <= 0 || this.initMeasure <= 0) {
      hilog.info(DOMAIN, 'MeasureAD', 'MeasureAD CalculateInitAbsorbance return 0');
      return 0;
    }

    abs = Math.log10(this.initReference / this.initMeasure);

    return abs * 1000;
  }

  /**
   * 计算空白吸光度
   * @returns 空白吸光度值（乘以1000）
   */
  CalculateBlankAbsorbance(): number {
    let abs = 0;
    if (this.blankReference <= 0 || this.blankMeasure <= 0) {
      hilog.info(DOMAIN, 'MeasureAD', 'MeasureAD CalculateBlankAbsorbance return 0');
      return 0;
    }

    abs = Math.log10(this.blankReference / this.blankMeasure);

    return abs * 1000;
  }
}
