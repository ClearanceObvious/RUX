# RUX
RUX (Robustly Unstable Xylophone) is a hobby project with a funny name. It's a programming language created on roblox.


# Language Basics
These are some basics about the RUX language so far

> ### Creating Variables

```js

let name = "Max";
let age = 21;

```


> ### Referencing Variables

```js

let number1 = 20;
let number2 = 50;

let result = ($number1 + $number2) * 2;   //Result is 40

```

> ### Concatinating Strings

```js

let first_name = "Max";
let last_name = "Michael";

let greeting = "Welcome";

let result = $greeting + ", " + $first_name + " " + $last_name + "!"; //Welcome, Max Michael!

```

> ### If Statements

```js

let name = "Michael"; let age = 15;

if ($age > 18 || $name == "Michael") {
  let message = "Correct!";
} else if ($age == 15 && $name == "Michael") {
  let message = "Found me!";
} else {
  let message = "Incorrect!";
}

```
