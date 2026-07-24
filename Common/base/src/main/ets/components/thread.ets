
import base from 'libbase.so';

export class thread{

  static sleep(millisecond:number){
    base.sleep(millisecond);
  }

  static getOSRunTime(){
    return base.getOSRunTime();
  }

  static getCurrentThreadId(){
    return base.getCurrentThreadId();
  }

}