---
title: Applying SOLID Principles in Java
author: Tawanda Munongo
bio: I spend most of my days learning about and building software systems. When I inevitably learn something new, I come here and write about it. Once in a while, I might throw in some fiction and philosophy.
linkedin: https://linkedin.com/in/tawanda-munongo
github: https://github.com/tmunongo
cover: https://res.cloudinary.com/ta1da-cloud/image/upload/v1695197030/realm/essays/solid_cegv3k.png
tags: ["Programming"]
description: In this post, discover how mastering the SOLID Principles in Java can transform your coding game and future-proof your projects.
publishDate: 2023-09-22
---

# Introduction

When tackling a complex software project, the importance of a well-structured codebase that is both extensible and maintainable cannot be overstated. If you're delving into the realm of object-oriented programming using Java, you'll inevitably seek a set of guiding principles and patterns to streamline your code's architecture. Look no further than the SOLID Principles of Object-Oriented Programming (OOP) to steer your Java journey towards optimal code organisation and future-proofing.

First introduced by Robert C. Martin, affectionately known as Uncle Bob, in his 2002 paper _[Design Principles and Design Patterns](https://fi.ort.edu.uy/innovaportal/file/2032/1/design_principles.pdf)_, these ideas were subsequently fleshed out by Michael Feathers who is credited with having coined the SOLID acronym. They give a comprehensive guide to best practices when designing classes or, in Uncle Bob's words:

> "[They aim] To create understandable, readable, and testable code that many developers can collaboratively work on."

The following five concepts make up the **SOLID** principles:

1. **S**ingle Responsibility
2. **O**pen/Closed Principle
3. **L**iskov Substitution
4. **I**nterface Segregation
5. **D**ependency Inversion

We are going to explore these concepts with some real-world and **Java** code examples that will give us deeper insight into what the principles are and how they can take our code to the next level.

# Single Responsibility Principle (SRP)

We are going to kick things off with the **Single Responsibility** Principle. As the name suggests, the principle states that a class must have a single responsibility and serve a single purpose. The idea being that if a class only has one job, then it will also only have a single reason to change.

For example, let's say we have a class that deals with generating an employee's payslip in a payroll system, it should only change when we make changes to how we calculate the employee's payslip. If we follow this, then our objects will only know what they need to know and not any unrelated behaviour.

## Bad Code Example

We can explore a code example that violates the SRP principle and show how it can be refactored by splitting the responsibilities into separate classes.

```java
    public class PayrollSystem {
    public double calculateSalary(Employee employee) {
        // ...
        return calculatedSalary;
    }

    public void generatePayslip(Employee employee) {
        // ...
        System.out.println("Payslip generated for " + employee.getName());
    }
}
```

In this example, the `Payroll System` class has two distinct responsibilities: calculating salaries and generating payslips. This violates SRP because a change in one responsibility may affect the other. This low separation of concerns may lead to highly fragile code.

## Good Code Example

To adhere to the SRP, we can take the same code and extract the different responsibilities of calculating salaries and generating payslips into distinct classes.

```java
    // Responsible for calculating employee salaries
public class SalaryCalculator {
    public double calculateSalary(Employee employee) {
        // Calculate the salary based on various factors
        // such as basic pay, allowances, and deductions
        // ...
        return calculatedSalary;
    }
}

// Responsible for generating employee payslips
public class PayslipGenerator {
    public void generatePayslip(Employee employee) {
        // Generate a payslip for the employee
        // including salary details, tax information, etc.
        // ...
        System.out.println("Payslip generated for " + employee.getName());
    }
}
```

Here, we have created two separate classes, `SalaryCalculator` and `PayslipGenerator`, each with a single responsibility. The `SalaryCalculator` class handles calculating salaries while `PayslipGenerator` is responsible for generating payslips. This code is cleaner and much easier to maintain as changes in one responsibility are less likely to impact the other.

## Advantages

Some of the advantages of _SRP_ are

- Our classes are more cohesive and robust
- Adhering to this principle also makes debugging easier as we can easily pinpoint the origin of a bug by virtue of knowing where to find the code that is supposed to perform a specific action.
- We can avoid code merge conflicts on teams because there's sufficient separation of concerns and little chance of members modifying the same code.

## Potential Pitfalls

One of the potential pitfalls when designing classes that follow the _Single Responsibility Principle_ is deciding on what counts as a single responsibility. What is a big enough responsibility for any given class? Taken too far, we may end up with classes with a single method that performs a single function.

The key here is to not overthink. For example, if we had a `MessageManipulator` class, it might be tempting to extract the methods to write and edit messages into separate classes as we may see those as distinct jobs. However, what we may end up with is two classes that are almost always used together because of how similar their functions are.

# Open/Closed Principle (OCP)

The second principle on our list is _OCP_. This idea, here, is that classes should be open for extension and closed to modification. Put in simple terms, we should be able to add new functionality to a class without having to modify any pre-existing code within that class.

As the old saying goes, _'if it ain't broke, don't fix it'_. If we find ourselves having to muddle around with old code to add new features, there's always the risk of introducing bugs where there were none. So, ideally, we want to avoid touching the tested and reliable code.

New features are added only by adding new code.

We achieve this by leveraging the power of interfaces and abstract classes. I'm going to go off on a tangent to briefly explore abstract classes and interfaces, so if you are already familiar, then feel free to skip ahead to the code examples.

Both abstract classes and interfaces are fundamental concepts in _OOP_ that establish contracts that subclasses must follow. They are similar with some different characteristics that enable them to serve different purposes.

### Abstract Classes

An _abstract_ class is one that cannot be instantiated on its own. It is meant to be a blueprint for other classes. An abstract class can have a mix of both abstract (unimplimented) methods and concrete (implemented) methods. We use abstract classes when we want a base class to establish some functionality that is shared by its subclasses, while also leaving some methods to be defined by each class.

```java
abstract class Animal {
    String name;

    // Abstract method to be implemented by subclasses
    abstract void makeSound();

		// shared method that can be used by all classes
    void sleep() {
        System.out.println(name + " is sleeping.");
    }
}

class Dog extends Animal {
    @Override
    void makeSound() {
        System.out.println("Woof!");
    }
}

class Cat extends Animal {
    @Override
    void makeSound() {
        System.out.println("Meow!");
    }
}
```

We can see that while the implementation of the `sleep()` method is shared by the `Dog` and `Cat` classes, both classes implement their own `makeSound()` method.

### Interfaces

On the other hand, an _interface_ is a collection of abstract methods (methods with no implementation) that a class can choose to implement. It can only contain method signatures, constants, and nested types. Unlike classes, interface can be implemented by multiple classes. They also allow multiple inheritances by allowing a class to implement multiple interfaces.

```java
interface Drawable {
    void draw(); // Method signature with no implementation
}

class Circle implements Drawable {
    @Override
    public void draw() {
        // Implementing the draw method for a Circle
        System.out.println("Drawing a circle.");
    }
}

class Square implements Drawable {
    @Override
    public void draw() {
        // Implementing the draw method for a Square
        System.out.println("Drawing a square.");
    }
}
```

In the above case, the `draw()` method has no implementation. Each class that chooses to implement the `Drawable` interface can have its own implementation.

## OCP Continued - Bad Code Example

Now, back to the _Open/Closed Principle_. We can imagine a `Shape` class with a method to calculate the area of a given shape. The class is structured such that we have a `type` field that holds the type of shape, and we rely on `if/else` blocks to decide how to calculate the area of each shape. We can represent this via a diagram as:

![Open/Closed Bad Example](https://res.cloudinary.com/ta1da-cloud/image/upload/v1695197281/realm/essays/Shape_n8t0kk.webp)

The diagram highlights the issue that we are trying to solve with _OCP_. Adding new shapes would require us to modify the `Shape` class to include additional logic to handle those new shapes. This goes against the _Open/Closed Principle_.

```java
class Shape {
    String type;

    Shape(String type) {
        this.type = type;
    }

    double calculateArea() {
        double area = 0.0;
        if (type.equals("Rectangle")) {
            // Calculate rectangle area
            area = /* ... */;
        } else if (type.equals("Circle")) {
            // Calculate circle area
            area = /* ... */;
        }
        return area;
    }
}

```

The code example may show the issue more clearly - to add support for more shapes in our class, we have to tack on more `if` statements.

## Good Code Example

We can address the problems with this code by leveraging inheritance and polymorphism.

```java
interface Shape {
    double calculateArea();
}

class Rectangle implements Shape {
    private double width;
    private double height;

    Rectangle(double width, double height) {
        this.width = width;
        this.height = height;
    }

    @Override
    public double calculateArea() {
        return width * height;
    }
}

class Circle implements Shape {
    private double radius;

    Circle(double radius) {
        this.radius = radius;
    }

    @Override
    public double calculateArea() {
        return Math.PI * radius * radius;
    }
}

```

In the refactored code, we add a new shape by creating a new class. This class will have its implementation of the `calculateArea()` method from the `Shape` interface. As illustrated in the diagram below, the `Shape` class remains agnostic about specific shapes, requiring no modifications when introducing new shapes into the program.

![Open/Closed Refactored](https://res.cloudinary.com/ta1da-cloud/image/upload/v1695197280/realm/essays/ShapeSRP_w9mkan.webp)

The diagram shows explicitly the contract that each shape must adhere to as defined by the interface it implements. We never need to touch one shape's area method to add a new shape and calculate its area. The same could be achieved with an abstract class, but this allows us to add multiple inheritance through interfaces in the future if a need to do so should ever arise.

# Liskov Substitution Principle (LSP)

The _L_ in **SOLID**, LSP states that objects of a superclass should be replaceable with objects of a subclass without affecting program correctness.

## Bad Code Example

```java
class Bird {
    void fly() {
        System.out.println("This bird can fly.");
    }
}

class Ostrich extends Bird {
    // Ostriches can't fly
    void fly() {
        throw new UnsupportedOperationException("Ostriches can't fly.");
    }
}

```

In this example, we have a base class `Bird` with a `fly()` method that suggests all birds can fly. However, when we create a subclass `Ostrich`, we override the `fly()` method and throw an exception to indicate that ostriches cannot fly. This violates the _Liskov Substitution Principle_ because a client expecting a general `Bird` object with the assumption that it can fly will encounter unexpected behaviour when working with an `Ostrich` object.

## Good Code Example

The solution is to use abstraction. We create an abstract `Bird` class with an abstract method `move()`.

```java
abstract class Bird {
    abstract void move();
}

class FlyingBird extends Bird {
    void move() {
        System.out.println("This bird can fly.");
    }
}

class Ostrich extends Bird {
    void move() {
        System.out.println("This bird cannot fly.");
    }
}

```

Why do we do this? The goal is to ensure that when working with `Bird` objects, we can be sure that a `move()` method exists and will behave according to the defined behaviour for each subclass.

This design allows for flexibility and interchangeability between different types of birds while preventing unexpected behaviour, thus promoting a more robust and maintainable codebase.

# Interface Segregation Principle

The `I` in **SOLID** stands for _Interface Segregation_. This design pattern is concerned with ensuring that classes are tailored to the needs of each particular client without forcing them to recognise functionality that is irrelevant to them.

Consider, for instance, the smartphones that have become indispensable to us all. Following a $1000 investment in the latest iPhone, a user might realise that they aren't utilising every feature the device offers. Some people use their phones mainly for web browsing, others for texting and calling, and others for taking photos.

It would be incredibly overwhelming for a user if all the features - calling, texting, web browsing, gaming, photography, etc. were all active all the time. In this scenario, adhering to _ISP_ means tailoring the interface of the smartphone to each user’s specific needs. Users should only interact with the desired features, making the device more user-friendly and efficient.

## Bad Code Example

```java
interface Machine {
    void print();
    void scan();
}

```

The above code is an example of a class that forces clients to implement both printing and scanning if they implement the `Machine` class. We would be forced to implement code to, for example, print, when our machine can only scan. This is a problem for clients that need only to implement one of those features. We can solve this by splitting this large interface into smaller ones.

```java
interface Printable {
    void print();
}

interface Scannable {
    void scan();
}

```

When our interfaces are designed this way, we can choose to implement `Printable` and `Scannable` as required by our machine.

The _Interface Segregation Principle_ promotes the creation of smaller, focused interfaces that cater to the specific needs of each client. This allows us to follow the principle of "client-specific interfaces" rather than "one-size-fits-all" interfaces. This contributes to more efficient and organised code in our software projects.

# Dependency Inversion Principle

In short, the dependency inversion principle refers to the decoupling of software modules. It states that high-level modules should not depend on low-level modules. Instead, both should rely on abstractions.

In simpler terms, `DIP` encourages decoupling between different components of a system by introducing interfaces or abstractions to mediate their interactions. This allows us greater flexibility to swap out parts without affecting the rest of the system.

Let's visualize this with a real-world example. Imagine we're building a gaming PC. Let's say that we have maxed out our budget on the core components - GPU, CPU, RAM, monitor, etc. We can pick up a cheap keyboard until we've made enough from our Patreons and YouTube memberships to upgrade to a higher-quality, mechanical keyboard. However, for now, the keyboard we select should not be so tightly coupled that we cannot easily replace it when we eventually decide to upgrade.

## Bad Code Example

Let's say we have a web application that requires a database connection for data persistence. We could structure it like this:

```java
public class WebApplication {
    public final MySQLDatabase connection;

    public WebApplication(MySQLDatabase connection) {
        connection = new MySQLDatabase();
    }
}

```

This code example demands that our web application accept a MySQL database connection. But what happens when, for whatever reason, we decide to migrate to Postgres or MongoDB? By declaring the DB connection with the _new_ keyword, we have tightly coupled the two classes. We can solve this by decoupling the database connection from our web app.

## Good Code Example

We can start by creating a more general `DatabaseConnection` interface.

```java
public interface DatabaseConnection{
    void connect(
        // variables for credentials
    );
}

```

Then we can refactor our class as shown below.

```java
public class WebApplication {
    public final DatabaseConnection connection;

    public WebApplication(DatabaseConnection connection) {
        this.connection = connection;
    }
}

```

Here, we use the `DI` pattern to facilitate adding the `DatabaseConnection` dependency into the `WebApplication` class. We also modify our `MySQLDatabase` class to implement `DatabaseConnection`.

```java
public class MySQLDatabase implements DatabaseConnection {
    @Override
    public void connect() {
        // TODO Auto-generated method stub

    }
}

```

With this decoupled structure, we can easily communicate through the `DatabaseConnection` abstraction. Not only that, but we can now easily replace the database in our web application with a different implementation of the interface.

```java
public static void main(String[] args) {
        MySQLDatabase mysqlConnect = new MySQLDatabase();
        PostgresDatabase pgConnect = new PostgresDatabase();

        WebApplication app = new WebApplication(pgConnect);
        WebApplication another_app = new WebApplication(mysqlConnect);

}

```

As we can see above, our web application can accept either database connection without any errors.

# Conclusion

As we have seen, the _SOLID_ principles are a set of guiding principles in object-oriented programming that aim to enhance code quality, maintainability, and flexibility. We can summarise them as follows:

- **SRP (Single Responsibility Principle)** advocates that a class should have a single reason to change, promoting a clear and focused purpose for each class.
- **OCP (Open-Closed Principle)** encourages classes to be open for extension but closed for modification, allowing code to be extended without altering existing implementations.
- **LSP (Liskov Substitution Principle)** ensures that objects of a subclass should be replaceable for objects of the superclass without altering the correctness of the program, promoting polymorphism and substitutability.
- **ISP (Interface Segregation Principle)** advises breaking down large, monolithic interfaces into smaller, more specialized ones to prevent classes from implementing methods they don't need, thereby keeping interfaces focused.
- **DIP (Dependency Inversion Principle)** emphasizes that high-level modules should not depend on low-level modules, but both should depend on abstractions, promoting loose coupling and flexibility.

Together, these principles form a foundation for writing clean, maintainable, and adaptable code. By adhering to these principles, developers can expect to produce code that is _less complex_, _easy to maintain_, _flexible_, _easy to test_, and _reusable_.

If you have made it this far, I hope that you’ll leave with an improved understanding of the **SOLID** principles. Even if you're not a Java developer, these principles can be applied to any other object-oriented programming language.

If you want to take it further, I will include some of the resources that I used to put this together. Hopefully, they can be as beneficial to you as they have been to me. If you have any thoughts or corrections, feel free to get in touch with me.

## Further Reading and Resources

- "Clean Code: A Handbook of Agile Software Craftsmanship" by Robert C. Martin - This book provides an in-depth exploration of SOLID principles and how to apply them in Java and other programming languages.
- [Uncle Bob SOLID principles - YouTube](https://www.youtube.com/watch?v=zHiWqnTWsn4)
- [Dependency Injection, The Best Pattern - Code Aesthetic (YouTube)](https://www.youtube.com/watch?v=J1f5b4vcxCQ)
- [How principled coders outperform the competition - Youtube](https://www.youtube.com/watch?v=q1qKv5TBaOA)
