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

let result = ($number1 + $number2) * 2;   //Result is 140

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

> ### Functions

```js

let divide := (x, y) {
  let result = 0;
  
  if ($y == 0) {
    $result = "Error, cannot divide by 0";
  } else {
    $result = $x / $y;
  }
  
  $log($result);
}

$divide(1, 0);  //Cannot Divide by 0

```


# Language Limitations

> ### Scopes

``` js

let age = 20;

let modifyAge := (newAge) {
  $age = $newAge;
}

$modifyAge(100);

$log($age);   //Still says 20, any changes to the globals in functions get reset

```

> ### Function arguments

```js

let add := (x, y) {
  return ($x + $y);
}

$add(1, 3); //4

$add((1 + 3), 3); //7

$add(1 + 3, 3);   //Syntax error, in order to provide a brand new expression as a paramater you must use a new pair of parentheses, like above

```
