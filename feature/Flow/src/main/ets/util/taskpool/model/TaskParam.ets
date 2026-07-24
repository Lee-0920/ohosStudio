// 任务参数类，所有任务参数定义在此

@Sendable
export class ParamA {
  private numA: number = 0;
  private numB: number = 1;

  constructor(numA: number, numB: number) {
    this.numA = numA;
    this.numB = numB;
  }

  getA() {
    return this.numA;
  }

  getB() {
    return this.numB;
  }

}

@Sendable
export class TestData {
  private name: string = '';
  private age: number = 18;

  constructor(name: string, age: number) {
    this.name = name;
    this.age = age;
  }

  getName() {
    return this.name;
  }

  getAge() {
    return this.age;
  }

  setName(name: string) {
    this.name = name;
  }
}