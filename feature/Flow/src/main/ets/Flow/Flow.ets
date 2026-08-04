import { hilog } from '@kit.PerformanceAnalysisKit'
import { thread } from "base"
import { taskpool } from '@kit.ArkTS';
import { MeasureResult } from './Measurer';

export class Flow {
  isStarted:boolean = false;
  isUserStop:boolean = false;
  isFinish:boolean = false;
  isDeviceFault:boolean = false;
  isFatalError:boolean = false;

  name:string = 'Sample';
  result:string = 'OK';
  constructor(name:string){
    this.name = name;
  }

  Stop():void {
    this.isStarted = false;
    this.isUserStop = true;
    //this.OnStop();
    hilog.info(120,'flow', 'flow.stop');
  }

  Wait(seconds: number): boolean {
    const targetMs = Math.floor(seconds * 5);
    let cnt = targetMs;

    while (true) {
      if (!taskpool.Task.isCanceled()) {
        //Sleep(200);
        thread.sleep(200);
      } else {
        hilog.info(120,'flow', 'flow.Wait.stop');
        return false;
      }

      cnt -= 1;
      if (cnt <= 0) {
        return true;
      }
    }
  }

  /**
   * 检查当前 Worker 任务是否已被取消（用户点击停止）。
   * 非测量流程的操作方法应在关键步骤间调用此函数，以支持及时响应停止指令。
   */
  IsCancelled(): boolean {
    return taskpool.Task.isCanceled();
  }

  GetRuntime(): number {
    return 0;
  }

  OnStart(): void {
    hilog.info(120,'flow', 'Flow OnStart');
  }

  OnProcess(): void {
    hilog.info(120,'flow', 'Flow OnProcess');
  }

  OnStop(): void {
    hilog.info(120,'flow', 'Flow OnStop');
  }

  Run(): [string, string] {
    hilog.info(120,'flow', 'Flow Run');
    this.isStarted = true;


    try {
      this.OnStart();
      this.OnProcess();
    } catch (err) {
      this.ExceptionHandle(err);
    }

    try {
      this.OnStop();
    } catch (err) {
      this.ExceptionHandle(err);
    }

    this.isStarted = false;

    // if (Measurer.instance?.flow) {
    //   Measurer.instance.Reset();
    // }

    if (this.isDeviceFault ) {

    }

    if (this.isFatalError) {

    }

    return [this.name, this.result];
  }

  ResultHandle?(result: MeasureResult){

  }

  ProformaResultHandle?(result: MeasureResult){

  }

  ExceptionHandle(err: Error): void {
    if (!err) {
      return;
    }else if(err){
      //hilog.info(120,'flow', 'Flow Run');
      hilog.info(120, 'flow', 'catch error :%{public}s', err.message)
    }

    // 此处可根据具体异常类型做更细致映射，包括 DeviceFaultException 等

    // 兼容 C++ userdata 风格异常需要在平台层适配
  }
}
