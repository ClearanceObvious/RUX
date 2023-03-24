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

> ### Loops

```js

for (let i = 20; $i < 100; $i = $i + 1) {
  $log($i);
}

let x = 0;
while ($x != 100) {
  $x = $x + 1;
  $log($x);
}

```


# Language Limitations

> ### Conditional Return / Break Statements

```js

let divide := (n1, n2) {
  if ($n2 == 0) {
    return "Cannot Divide by 0";  //Does not work if it's in If Statement
  } else {
    return ($n1 / $n2);   //Does not work if it's in If Statement
  }
}

//FIX (VER 1.7>)
let divide := (n1, n2) {
  !(n2 == 0) return "Cannot Divide by 0"; //Works through "Conditional Statement"
  return ($n1 / $n2)                      //Otherwise Returns division
}

$log($divide(1, 2));                      //Outputs properly

```
