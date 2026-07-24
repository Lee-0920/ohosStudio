# ArkTS 基础语法及示例

## 介绍

ArkTS 是华为 HarmonyOS 的编程语言，基于 TypeScript，用于开发 HarmonyOS 应用。它在继承 TypeScript 语法的基础上进行了优化，专注于低运行时开销，提供更高的性能和开发效率。ArkTS 对 TypeScript 的动态类型特性施加了更严格的限制，以减少运行时开销，提高执行效率。

## 变量和常量

### 变量声明
使用 `let` 声明的变量可以在程序执行期间具有不同的值。

```typescript
let name: string = "ArkTS";
let count: number = 42;
```

### 常量声明
使用 `const` 声明的常量为只读类型，只能被赋值一次。对常量重新赋值会造成编译时错误。

```typescript
const version: number = 1.0;
const PI = 3.14159;
```

### 类型推断
如果变量或常量的声明包含初始值，开发者无需显式指定类型，ArkTS 会自动推断类型。

```typescript
let message = "Hello, ArkTS!"; // 推断为 string
let count = 42; // 推断为 number
```

## 数据类型

### 基本类型和引用类型

**基本类型**包括 `number`、`string`、`boolean` 等简单类型，存储和访问都是直接的，比较时直接比较其值。

**引用类型**包括对象、数组和函数等复杂数据结构，通过引用访问数据，修改引用会影响原始数据。

### number 类型
ArkTS 提供 `number` 类型，任何整数和浮点数都可以被赋给此类型的变量。

**整数字面量：**
- 十进制整数：`0`、`117`、`-345`
- 十六进制整数：`0x1123`、`0x00111`、`-0xF1A7`（以 `0x` 或 `0X` 开头）
- 八进制整数：`0o777`（以 `0o` 或 `0O` 开头）
- 二进制整数：`0b11`、`0b0011`、`-0b11`（以 `0b` 或 `0B` 开头）

**浮点数字面量：**
```typescript
let num1: number = 3.14;
let num2: number = 1.5e10; // 科学计数法
```

> **注意**：`number` 类型在表示大整数（超过 `-9007199254740991~9007199254740991`）时会造成精度丢失，可使用 `bigint` 类型来确保精度。

### boolean 类型
`boolean` 类型由 `true` 和 `false` 两个逻辑值组成。

```typescript
let isEnabled: boolean = true;
let hasError: boolean = false;
```

### string 类型
`string` 类型代表字符序列，可以使用单引号、双引号或反向单引号（模板字面量）。

```typescript
let singleQuote: string = 'Hello';
let doubleQuote: string = "World";
let templateLiteral: string = `Hello, ${name}!`; // 支持插值
```

### void 类型
`void` 类型用于指定函数没有返回值，此类型只有一个值 `void`。

```typescript
function logMessage(message: string): void {
  console.log(message);
}
```

### Object 类型
`Object` 类型是所有引用类型的基类型。任何值都可以直接被赋给 `Object` 类型的变量（基本类型值会被自动装箱）。

```typescript
let obj: Object = { name: "Alice" };
let numObj: Object = 42; // 自动装箱
```

### array 类型
数组是由可赋值给数组声明中指定元素类型的数据组成的对象。

```typescript
let numbers: number[] = [1, 2, 3, 4, 5];
let strings: Array<string> = ["a", "b", "c"];
```

### enum 类型
枚举类型是预先定义的一组命名值的值类型，使用枚举常量时必须以枚举类型名称为前缀。

```typescript
enum Color {
  Red,    // 默认值为 0
  Green,  // 默认值为 1
  Blue    // 默认值为 2
}

enum Direction {
  Left = 10,
  Right = 20,
  Up = 30,
  Down = 40
}

let color: Color = Color.Red;
console.log(Color.Green); // 输出 1
```

### Union 类型（联合类型）
联合类型是由多个类型组合成的引用类型，包含了变量可能的所有类型。

```typescript
let value: string | number;
value = "hello";
value = 123;

function printId(id: string | number): void {
  console.log(`ID: ${id}`);
}
```

### Aliases 类型（类型别名）
为匿名类型提供名称，或为已定义的类型提供替代名称。

```typescript
type StringOrNumber = string | number;
type User = {
  id: number;
  name: string;
};

let value: StringOrNumber = "test";
let user: User = { id: 1, name: "Alice" };
```

## 运算符

### 赋值运算符
- `=`：赋值
- 复合赋值：`+=`、`-=`、`*=`、`/=`、`%=`、`<<=`、`>>=`、`>>>=`、`&=`、`|=`、`^=`

```typescript
let a = 10;
a += 5; // 等价于 a = a + 5
```

### 比较运算符

| 运算符 | 说明 |
|--------|------|
| `===` | 严格相等（类型和值都相等） |
| `!==` | 严格不相等 |
| `==` | 相等（允许类型转换） |
| `!=` | 不相等 |
| `>` | 大于 |
| `>=` | 大于等于 |
| `<` | 小于 |
| `<=` | 小于等于 |

### 算术运算符
- 一元运算符：`-`、`+`、`--`、`++`
- 二元运算符：`+`（加法）、`-`（减法）、`*`（乘法）、`/`（除法）、`%`（取余）

### 位运算符

| 运算符 | 说明 |
|--------|------|
| `a & b` | 按位与 |
| `a | b` | 按位或 |
| `a ^ b` | 按位异或 |
| `~a` | 按位非 |
| `a << b` | 左移 |
| `a >> b` | 算术右移（带符号扩展） |
| `a >>> b` | 逻辑右移（左边补0） |

### 逻辑运算符

| 运算符 | 说明 |
|--------|------|
| `a && b` | 逻辑与 |
| `a \|\| b` | 逻辑或 |
| `!a` | 逻辑非 |

### instanceof 运算符
用于在运行时检查一个对象是否是指定类或其子类的实例。

```typescript
class Person {}
class Student extends Person {}

let student = new Student();
console.log(student instanceof Person); // true
console.log(student instanceof Student); // true
```

## 控制结构

### if 语句
条件表达式可以是任何类型，非 `boolean` 类型会进行隐式类型转换。

```typescript
if (condition) {
  // code
} else if (anotherCondition) {
  // code
} else {
  // code
}
```

### switch 语句
执行与 `switch` 表达式值匹配的代码块。

```typescript
switch (value) {
  case 1:
    console.log('One');
    break;
  case 2:
    console.log('Two');
    break;
  default:
    console.log('Other');
}
```

### 条件表达式（三元运算符）
根据第一个表达式的布尔值返回其他两个表达式之一的结果。

```typescript
let result = condition ? expression1 : expression2;
let message = score >= 60 ? 'Pass' : 'Fail';
```

### for 语句

```typescript
for (let i = 0; i < 10; i++) {
  console.log(i);
}
```

### for-of 语句
用于遍历数组、Set、Map、字符串等可迭代类型。

```typescript
let array = [1, 2, 3];
for (let item of array) {
  console.log(item);
}
```

### while 语句

```typescript
let i = 0;
while (i < 10) {
  console.log(i);
  i++;
}
```

### do-while 语句
至少执行一次循环体。

```typescript
let i = 0;
do {
  console.log(i);
  i++;
} while (i < 10);
```

### break 和 continue 语句
- `break`：终止循环或 `switch`
- `continue`：跳过当前迭代，继续下一次迭代

```typescript
for (let i = 0; i < 10; i++) {
  if (i === 5) break; // 终止循环
  console.log(i);
}

for (let i = 0; i < 10; i++) {
  if (i % 2 === 0) continue; // 跳过偶数
  console.log(i);
}
```

### throw 和 try-catch 语句

```typescript
try {
  throw new Error('Something went wrong');
} catch (error) {
  console.error(error.message);
} finally {
  console.log('Always executed');
}
```

## 函数

### 函数声明
函数声明引入一个函数，包含名称、参数列表、返回类型和函数体。

```typescript
function greet(name: string): string {
  return `Hello, ${name}!`;
}
```

### 可选参数
可选参数的格式为 `name?: Type`，也可以设置默认值。

```typescript
function buildName(firstName: string, lastName?: string): string {
  return lastName ? `${firstName} ${lastName}` : firstName;
}

function multiply(a: number, b: number = 2): number {
  return a * b;
}
```

### rest 参数
函数的最后一个参数可以是 rest 参数，格式为 `...restName: Type[]`。

```typescript
function sum(...numbers: number[]): number {
  return numbers.reduce((acc, val) => acc + val, 0);
}

sum(1, 2, 3, 4); // 返回 10
```

### 返回类型
如果可以从函数体内推断出函数返回类型，则可省略标注。

```typescript
function add(a: number, b: number) {
  return a + b; // 推断返回 number
}
```

### 函数类型
函数类型通常用于定义回调函数。

```typescript
type Callback = (result: string) => void;

function fetchData(callback: Callback): void {
  callback('Data fetched');
}
```

### 箭头函数（Lambda 函数）

```typescript
const greet = (name: string): string => `Hello, ${name}!`;
const add = (a: number, b: number) => a + b;
```

### 闭包
闭包是由函数及声明该函数的环境组合而成的。

```typescript
function createCounter() {
  let count = 0;
  return () => {
    count++;
    return count;
  };
}

const counter = createCounter();
console.log(counter()); // 1
console.log(counter()); // 2
```

### 函数重载
通过编写重载，指定函数的不同调用方式。

```typescript
function format(value: string): string;
function format(value: number): string;
function format(value: string | number): string {
  return String(value);
}

format('hello'); // 调用第一个重载
format(42); // 调用第二个重载
```

## 类和接口

### 类声明

```typescript
class Person {
  name: string;
  age: number;

  constructor(name: string, age: number) {
    this.name = name;
    this.age = age;
  }

  greet(): string {
    return `Hello, my name is ${this.name}`;
  }
}
```

### 字段

#### 实例字段
实例字段存在于类的每个实例上，每个实例都有自己的实例字段集合。

#### 静态字段
使用关键字 `static` 声明静态字段，属于类本身，所有实例共享。

```typescript
class Counter {
  static instanceCount: number = 0;
  
  constructor() {
    Counter.instanceCount++;
  }
}

const c1 = new Counter();
const c2 = new Counter();
console.log(Counter.instanceCount); // 2
```

#### 字段初始化
ArkTS 要求所有字段在声明时或构造函数中显式初始化。

```typescript
class Example {
  // 正确：声明时初始化
  value1: number = 0;
  
  // 正确：构造函数中初始化
  value2: number;
  
  constructor() {
    this.value2 = 1;
  }
}
```

### getter 和 setter
用于提供对类属性的受控访问。

```typescript
class Person {
  private _age: number = 0;
  
  get age(): number {
    return this._age;
  }
  
  set age(newAge: number) {
    if (newAge >= 0 && newAge <= 120) {
      this._age = newAge;
    } else {
      throw new Error('Invalid age');
    }
  }
}

const person = new Person();
person.age = 25; // 使用 setter
console.log(person.age); // 使用 getter
```

### 方法

#### 实例方法
必须通过类的实例调用。

```typescript
class Rectangle {
  width: number;
  height: number;
  
  constructor(width: number, height: number) {
    this.width = width;
    this.height = height;
  }
  
  calculateArea(): number {
    return this.width * this.height;
  }
}

const rect = new Rectangle(10, 20);
console.log(rect.calculateArea()); // 200
```

#### 静态方法
使用关键字 `static` 声明，属于类本身，只能访问静态字段。

```typescript
class MathUtils {
  static PI: number = 3.14159;
  
  static calculateCircumference(radius: number): number {
    return 2 * MathUtils.PI * radius;
  }
}

console.log(MathUtils.calculateCircumference(5)); // 31.4159
```

### 继承
一个类可以继承另一个类，并实现多个接口。

```typescript
class Student extends Person {
  studentId: string;
  
  constructor(name: string, age: number, studentId: string) {
    super(name, age); // 调用父类构造函数
    this.studentId = studentId;
  }
}
```

### 方法重写
子类可以重写父类中定义的方法。

```typescript
class GraduateStudent extends Student {
  degree: string;
  
  constructor(name: string, age: number, studentId: string, degree: string) {
    super(name, age, studentId);
    this.degree = degree;
  }
  
  greet(): string {
    return `${super.greet()}, I have a ${this.degree} degree`;
  }
}
```

### 可见性修饰符

| 修饰符 | 说明 |
|--------|------|
| `public` | 公有成员，任何地方都可见（默认） |
| `private` | 私有成员，只能在声明该成员的类中访问 |
| `protected` | 受保护成员，可在类及其派生类中访问 |

```typescript
class Example {
  public publicField: string = 'public';
  private privateField: string = 'private';
  protected protectedField: string = 'protected';
  
  private privateMethod(): void {
    console.log('private');
  }
}

class SubExample extends Example {
  accessProtected(): void {
    console.log(this.protectedField); // 可以访问
    // console.log(this.privateField); // 错误：无法访问私有成员
  }
}
```

### 抽象类
带有 `abstract` 修饰符的类称为抽象类，无法实例化。

```typescript
abstract class Shape {
  abstract calculateArea(): number;
}

class Circle extends Shape {
  radius: number;
  
  constructor(radius: number) {
    super();
    this.radius = radius;
  }
  
  calculateArea(): number {
    return Math.PI * this.radius * this.radius;
  }
}
```

### 接口
接口是定义代码协定的常见方式，任何实现了特定接口的类实例都可通过该接口实现多态。

```typescript
interface Person {
  name: string;
  age: number;
  greet(): string;
}

class Employee implements Person {
  name: string;
  age: number;
  
  constructor(name: string, age: number) {
    this.name = name;
    this.age = age;
  }
  
  greet(): string {
    return `Hello, I'm ${this.name}`;
  }
}
```

### 接口继承
接口可以继承其他接口。

```typescript
interface Shape {
  area: number;
}

interface Circle extends Shape {
  radius: number;
}

interface Rectangle extends Shape {
  width: number;
  height: number;
}
```

### 对象字面量
可用于创建类实例并提供初始值。

```typescript
const person: Person = {
  name: "Alice",
  age: 30,
  greet: () => "Hello"
};
```

## 泛型类型和函数

### 泛型类和接口

```typescript
class CustomStack<Element> {
  private elements: Element[] = [];
  
  push(element: Element): void {
    this.elements.push(element);
  }
  
  pop(): Element | undefined {
    return this.elements.pop();
  }
}

const stack = new CustomStack<number>();
stack.push(1);
stack.push(2);
```

### 泛型约束
限制类型参数只能取某些特定的值。

```typescript
interface Hashable {
  hash(): number;
}

class MyHashMap<Key extends Hashable, Value> {
  private map: Map<number, Value> = new Map();
  
  set(key: Key, value: Value): void {
    const hash = key.hash();
    this.map.set(hash, value);
  }
}
```

### 泛型函数

```typescript
function getLastElement<T>(array: T[]): T | undefined {
  return array[array.length - 1];
}

const numbers = [1, 2, 3];
const last = getLastElement(numbers); // 类型推断为 number
```

### 泛型默认值

```typescript
class Container<T = string> {
  value: T;
  
  constructor(value: T) {
    this.value = value;
  }
}

const container1 = new Container("hello"); // T = string
const container2 = new Container<number>(42); // T = number
```

## 空安全

ArkTS 中的所有类型默认不允许为空，类似于 TypeScript 的 `strictNullChecks` 模式。

### 可空类型
使用联合类型 `T | null` 定义可空值的变量。

```typescript
let name: string | null = null;
name = "Alice";
```

### 非空断言运算符
后缀运算符 `!` 用于断言其操作数为非空。

```typescript
function getLength(str: string | null): number {
  return str!.length; // 断言 str 不为 null
}
```

### 空值合并运算符
`??` 用于检查左侧表达式是否为 `null` 或 `undefined`。

```typescript
function getNick(nick: string | null | undefined): string {
  return nick ?? ""; // 如果 nick 为 null 或 undefined，返回空字符串
}
```

### 可选链
访问对象属性时，如果属性是 `undefined` 或 `null`，可选链运算符返回 `undefined`。

```typescript
interface Person {
  spouse?: {
    nick?: string;
  };
}

function getSpouseNick(person: Person): string | null | undefined {
  return person.spouse?.nick;
}
```

## 模块

### 导出
使用关键字 `export` 导出顶层声明。

```typescript
// utils.ts
export function add(a: number, b: number): number {
  return a + b;
}

export const PI = 3.14159;

export default class Calculator {}
```

### 导入

#### 静态导入

```typescript
// main.ts
import { add, PI } from './utils';
import Calculator from './utils';
import * as utils from './utils';
```

#### 动态导入
用于根据条件或按需导入模块，返回一个 Promise。

```typescript
async function loadModule() {
  const module = await import('./utils');
  console.log(module.add(2, 3));
}
```

### 导入 HarmonyOS SDK
通过导入 Kit 方式使用开放能力。

```typescript
// 方式一：导入单个模块
import { taskpool } from '@kit.ArkTS';

// 方式二：导入多个模块
import { taskpool, worker } from '@kit.ArkTS';

// 方式三：导入所有模块（不推荐，会增加包体积）
import * as arkts from '@kit.ArkTS';
```

## 注解（Annotation）

注解通过添加元数据来改变应用声明的语义。

### 用户自定义注解
从 API version 20 及之后版本支持用户自定义注解。

```typescript
@interface MyAnnotation {
  value: string;
  count?: number;
}

@MyAnnotation({ value: "test", count: 5 })
class MyClass {
  @MyAnnotation({ value: "method" })
  myMethod(): void {}
}
```

### 注解字段类型
注解字段仅限于以下类型：
- `number`
- `boolean`
- `string`
- 枚举
- 以上类型的数组

## 示例：简单应用

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

class UserService {
  private users: User[] = [];

  addUser(user: User): void {
    this.users.push(user);
  }

  getUserById(id: number): User | undefined {
    return this.users.find(user => user.id === id);
  }

  getAllUsers(): User[] {
    return this.users;
  }
}

const service = new UserService();
service.addUser({ id: 1, name: "Alice", email: "alice@example.com" });
service.addUser({ id: 2, name: "Bob", email: "bob@example.com" });

const user = service.getUserById(1);
if (user) {
  console.log(`User: ${user.name}, Email: ${user.email}`);
}

const allUsers = service.getAllUsers();
console.log(`Total users: ${allUsers.length}`);
```

## 总结

ArkTS 提供了强大的类型系统和现代 JavaScript/TypeScript 特性，专注于低运行时开销，使开发 HarmonyOS 应用更加安全和高效。通过空安全、泛型、注解等特性，ArkTS 为开发者提供了更好的开发体验和更高的代码质量。更多高级特性请参考官方文档。

# ArkTS UI 特性及示例解析

## UI 框架概述

ArkTS UI 基于声明式 UI 范式，允许开发者使用简洁的代码描述 UI 结构。UI 组件是可组合的，支持状态管理和事件处理。

## 基本组件

### Text 组件
用于显示文本。

```typescript
@Entry
@Component
struct HelloWorld {
  build() {
    Text('Hello, ArkTS!')
      .fontSize(20)
      .fontColor(Color.Black)
  }
}
```

### Button 组件
用于创建按钮。

```typescript
@Entry
@Component
struct ButtonExample {
  build() {
    Button('Click Me')
      .onClick(() => {
        console.log('Button clicked!');
      })
  }
}
```

## 布局组件

### Column 和 Row
Column 用于垂直布局，Row 用于水平布局。

```typescript
@Entry
@Component
struct LayoutExample {
  build() {
    Column() {
      Text('First Item')
      Text('Second Item')
      Row() {
        Text('Left')
        Text('Right')
      }
    }
  }
}
```

## 状态管理

使用 @State 装饰器管理组件状态。

```typescript
@Entry
@Component
struct Counter {
  @State count: number = 0;

  build() {
    Column() {
      Text(`Count: ${this.count}`)
      Button('Increment')
        .onClick(() => {
          this.count++;
        })
    }
  }
}
```

## 事件处理

组件支持各种事件，如点击、长按等。

```typescript
@Entry
@Component
struct EventExample {
  @State message: string = 'Tap me!';

  build() {
    Text(this.message)
      .onClick(() => {
        this.message = 'Clicked!';
      })
      .onLongPress(() => {
        this.message = 'Long pressed!';
      })
  }
}
```

## 样式和主题

使用属性设置样式，如颜色、字体、大小等。

```typescript
@Entry
@Component
struct StyleExample {
  build() {
    Column() {
      Text('Styled Text')
        .fontSize(24)
        .fontColor(Color.Red)
        .backgroundColor(Color.Yellow)
        .padding(10)
    }
  }
}
```

## 自定义组件

创建可重用的组件。

```typescript
@Component
struct CustomButton {
  @Prop text: string;

  build() {
    Button(this.text)
      .width(100)
      .height(50)
  }
}

@Entry
@Component
struct App {
  build() {
    Column() {
      CustomButton({ text: 'Button 1' })
      CustomButton({ text: 'Button 2' })
    }
  }
}
```

## 示例：简单页面

```typescript
@Entry
@Component
struct SimplePage {
  @State name: string = '';
  @State age: number = 0;

  build() {
    Column({ space: 20 }) {
      Text('User Info')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: 'Enter name' })
        .onChange((value) => {
          this.name = value;
        })

      TextInput({ placeholder: 'Enter age', inputFilter: '[0-9]*' })
        .onChange((value) => {
          this.age = parseInt(value) || 0;
        })

      Text(`Name: ${this.name}, Age: ${this.age}`)

      Button('Submit')
        .onClick(() => {
          console.log(`Submitted: ${this.name}, ${this.age}`);
        })
    }
    .padding(20)
    .width('100%')
    .height('100%')
  }
}
```

## 总结

ArkTS UI 提供了丰富的组件和布局选项，使开发者能够快速构建美观且功能丰富的用户界面。通过状态管理和事件处理，可以创建交互式的应用。更多 UI 特性请参考 HarmonyOS 官方文档。

# ArkTS 线程详解

## 介绍

在 ArkTS 中，线程管理是开发高效 HarmonyOS 应用的关键部分。ArkTS 支持多种并发机制，包括 TaskPool、Worker 和异步调用（如 Promise 和 async/await），以便在不阻塞主线程的情况下执行耗时操作。

## TaskPool

TaskPool 是 ArkTS 提供的一种轻量级并发执行机制，用于在后台线程池中执行任务。它适合执行 CPU 密集型或 I/O 密集型的短任务。

### 基本用法

```typescript
import { taskpool } from '@kit.ArkTS';

@Entry
@Component
struct TaskPoolExample {
  @State result: string = 'Result will appear here';

  async executeTask() {
    try {
      const task = () => {
        let sum = 0;
        for (let i = 0; i < 1000000; i++) {
          sum += i;
        }
        return sum;
      };

      const taskResult = await taskpool.execute(task);
      this.result = `Task result: ${taskResult}`;
    } catch (error) {
      this.result = `Error: ${error.message}`;
    }
  }

  build() {
    Column() {
      Text(this.result)
      Button('Execute Task')
        .onClick(() => {
          this.executeTask();
        })
    }
  }
}
```

### 高级用法：任务组

```typescript
import { taskpool } from '@kit.ArkTS';

async function executeMultipleTasks() {
  const tasks = [
    () => { /* task 1 */ return 1; },
    () => { /* task 2 */ return 2; },
    () => { /* task 3 */ return 3; }
  ];

  try {
    const results = await taskpool.executeAll(tasks);
    console.log('All results:', results);
  } catch (error) {
    console.error('Error executing tasks:', error);
  }
}
```

## Worker

Worker 允许在独立的线程中运行脚本，与主线程并行执行。适用于需要长时间运行或计算密集型的任务。

### 创建 Worker

```typescript
import { worker } from '@kit.ArkTS';

@Entry
@Component
struct WorkerExample {
  @State message: string = 'Waiting for worker...';
  private workerInstance: worker.Worker | null = null;

  startWorker() {
    this.workerInstance = new worker.Worker('entry/ets/workers/worker.ts');
    
    this.workerInstance.onmessage = (e) => {
      this.message = `Received: ${e.data}`;
    };

    this.workerInstance.onerror = (e) => {
      this.message = `Error: ${e.message}`;
    };

    this.workerInstance.postMessage('Hello from main thread');
  }

  stopWorker() {
    if (this.workerInstance) {
      this.workerInstance.terminate();
      this.workerInstance = null;
      this.message = 'Worker stopped';
    }
  }

  build() {
    Column() {
      Text(this.message)
      Button('Start Worker')
        .onClick(() => {
          this.startWorker();
        })
      Button('Stop Worker')
        .onClick(() => {
          this.stopWorker();
        })
    }
  }
}
```

### Worker 脚本

```typescript
// entry/ets/workers/worker.ts
import { worker } from '@kit.ArkTS';

const workerPort = worker.workerPort;

workerPort.onmessage = (e) => {
  console.log('Worker received:', e.data);
  
  const result = performHeavyComputation();
  
  workerPort.postMessage(result);
};

function performHeavyComputation(): number {
  let result = 0;
  for (let i = 0; i < 10000000; i++) {
    result += Math.sin(i);
  }
  return result;
}
```

## 异步调用

ArkTS 支持 Promise 和 async/await，用于处理异步操作。

### Promise

```typescript
function fetchData(): Promise<string> {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (Math.random() > 0.5) {
        resolve('Data fetched successfully');
      } else {
        reject(new Error('Failed to fetch data'));
      }
    }, 1000);
  });
}

@Entry
@Component
struct PromiseExample {
  @State status: string = 'Click to fetch data';

  async fetchDataAsync() {
    try {
      this.status = 'Fetching...';
      const result = await fetchData();
      this.status = result;
    } catch (error) {
      this.status = `Error: ${error.message}`;
    }
  }

  build() {
    Column() {
      Text(this.status)
      Button('Fetch Data')
        .onClick(() => {
          this.fetchDataAsync();
        })
    }
  }
}
```

### async/await

```typescript
async function processData(data: string): Promise<string> {
  await new Promise(resolve => setTimeout(resolve, 500));
  return data.toUpperCase();
}

async function mainProcess() {
  try {
    const step1 = await processData('hello');
    const step2 = await processData(step1 + ' world');
    console.log('Final result:', step2);
  } catch (error) {
    console.error('Error in main process:', error);
  }
}
```

## 综合示例

```typescript
import { taskpool, worker } from '@kit.ArkTS';

@Entry
@Component
struct ComprehensiveExample {
  @State status: string = 'Ready';
  private workerInstance: worker.Worker | null = null;

  async runComprehensiveTask() {
    this.status = 'Starting comprehensive task...';

    try {
      const parallelTasks = [
        () => calculateSum(1000000),
        () => calculateSum(2000000),
        () => calculateSum(3000000)
      ];
      
      const parallelResults = await taskpool.executeAll(parallelTasks);
      console.log('Parallel results:', parallelResults);

      this.workerInstance = new worker.Worker('entry/ets/workers/heavy_worker.ts');
      this.workerInstance.postMessage({ numbers: parallelResults });

      this.workerInstance.onmessage = (e) => {
        this.status = `Worker result: ${e.data}`;
        this.workerInstance?.terminate();
      };

      this.workerInstance.onerror = (e) => {
        this.status = `Worker error: ${e.message}`;
      };

    } catch (error) {
      this.status = `Error: ${error.message}`;
    }
  }

  build() {
    Column() {
      Text(this.status)
      Button('Run Comprehensive Task')
        .onClick(() => {
          this.runComprehensiveTask();
        })
    }
  }
}

function calculateSum(n: number): number {
  let sum = 0;
  for (let i = 1; i <= n; i++) {
    sum += i;
  }
  return sum;
}
```

## 注意事项

1. **线程安全**：在多线程环境中，确保共享数据的线程安全。避免在 Worker 中直接修改主线程的状态。

2. **资源管理**：及时终止 Worker 实例，避免资源泄漏。

3. **错误处理**：始终使用 try-catch 处理异步操作中的错误。

4. **性能考虑**：TaskPool 适合短任务，Worker 适合长任务。过度使用可能导致性能下降。

5. **平台限制**：某些 HarmonyOS 设备可能对并发线程数量有限制。

通过合理使用这些并发机制，可以显著提升 ArkTS 应用的性能和用户体验。更多详细信息请参考 HarmonyOS 官方文档。
