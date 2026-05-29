# ArkTS 基础语法及示例

## 介绍

ArkTS 是华为 HarmonyOS 的编程语言，基于 TypeScript，用于开发 HarmonyOS 应用。它支持静态类型检查、面向对象编程等特性。

## 变量和常量

### 变量声明
使用 `let` 声明变量，`const` 声明常量。

```typescript
let name: string = "ArkTS";
const version: number = 1.0;
```

### 类型推断
ArkTS 支持类型推断，无需显式指定类型。

```typescript
let message = "Hello, ArkTS!"; // 推断为 string
let count = 42; // 推断为 number
```

## 数据类型

ArkTS 支持以下基本数据类型：

- `boolean`: true 或 false
- `number`: 整数或浮点数
- `string`: 字符串
- `void`: 无返回值
- `null` 和 `undefined`

### 数组
```typescript
let numbers: number[] = [1, 2, 3, 4, 5];
let strings: Array<string> = ["a", "b", "c"];
```

### 对象
```typescript
let person: { name: string; age: number } = {
  name: "Alice",
  age: 30
};
```

### 联合类型
```typescript
let value: string | number;
value = "hello";
value = 123;
```

## 函数

### 函数声明
```typescript
function greet(name: string): string {
  return `Hello, ${name}!`;
}
```

### 箭头函数
```typescript
const greet = (name: string): string => {
  return `Hello, ${name}!`;
};
```

### 可选参数和默认参数
```typescript
function buildName(firstName: string, lastName?: string): string {
  return lastName ? `${firstName} ${lastName}` : firstName;
}

function multiply(a: number, b: number = 2): number {
  return a * b;
}
```

## 类和接口

### 接口
```typescript
interface Person {
  name: string;
  age: number;
  greet(): string;
}
```

### 类
```typescript
class Student implements Person {
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

### 继承
```typescript
class GraduateStudent extends Student {
  degree: string;

  constructor(name: string, age: number, degree: string) {
    super(name, age);
    this.degree = degree;
  }
}
```

## 控制结构

### 条件语句
```typescript
if (condition) {
  // code
} else if (anotherCondition) {
  // code
} else {
  // code
}
```

### 循环
```typescript
// for 循环
for (let i = 0; i < 10; i++) {
  console.log(i);
}

// while 循环
let i = 0;
while (i < 10) {
  console.log(i);
  i++;
}

// for...of 循环
let array = [1, 2, 3];
for (let item of array) {
  console.log(item);
}
```

## 模块

### 导出
```typescript
// utils.ts
export function add(a: number, b: number): number {
  return a + b;
}

export const PI = 3.14159;
```

### 导入
```typescript
// main.ts
import { add, PI } from './utils';
console.log(add(2, 3)); // 5
console.log(PI); // 3.14159
```

## 示例：简单应用

```typescript
// 定义接口
interface User {
  id: number;
  name: string;
  email: string;
}

// 定义类
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

// 使用
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

ArkTS 提供了强大的类型系统和现代 JavaScript/TypeScript 特性，使开发 HarmonyOS 应用更加安全和高效。以上是基础语法和示例，更多高级特性请参考官方文档。

# ArkTS UI 特性及示例解析

## UI 框架概述

ArkTS UI 基于声明式UI范式，允许开发者使用简洁的代码描述UI结构。UI组件是可组合的，支持状态管理和事件处理。

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

ArkTS UI 提供了丰富的组件和布局选项，使开发者能够快速构建美观且功能丰富的用户界面。通过状态管理和事件处理，可以创建交互式的应用。更多UI特性请参考 HarmonyOS 官方文档。

