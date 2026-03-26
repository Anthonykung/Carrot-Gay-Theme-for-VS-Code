/*
 * SPDX-License-Identifier: MIT
 * Author: Anthony Kung <hi@anth.dev> (anth.dev)
 *
 * Tiny demo calculator app
 */

type Operator = "+" | "-" | "*" | "/";
type ButtonTone = "number" | "operator" | "action" | "display";

interface ButtonStyle {
  label: string;
  tone: ButtonTone;
  hex: `#${string}`;
}

const buttonStyles: Record<string, ButtonStyle> = {
  "0": { label: "0", tone: "number", hex: "#9cf6c8" },
  "1": { label: "1", tone: "number", hex: "#9cf6c8" },
  "2": { label: "2", tone: "number", hex: "#9cf6c8" },
  "3": { label: "3", tone: "number", hex: "#9cf6c8" },
  "4": { label: "4", tone: "number", hex: "#9cf6c8" },
  "5": { label: "5", tone: "number", hex: "#9cf6c8" },
  "6": { label: "6", tone: "number", hex: "#9cf6c8" },
  "7": { label: "7", tone: "number", hex: "#9cf6c8" },
  "8": { label: "8", tone: "number", hex: "#9cf6c8" },
  "9": { label: "9", tone: "number", hex: "#9cf6c8" },
  ".": { label: ".", tone: "number", hex: "#9cf6c8" },
  "+": { label: "+", tone: "operator", hex: "#47c7ff" },
  "-": { label: "-", tone: "operator", hex: "#47c7ff" },
  "*": { label: "x", tone: "operator", hex: "#47c7ff" },
  "/": { label: "/", tone: "operator", hex: "#47c7ff" },
  "=": { label: "=", tone: "action", hex: "#ff7dc2" },
  "C": { label: "C", tone: "action", hex: "#ff7dc2" },
};

class CalculatorApp {
  private left = "0";
  private right = "";
  private operator: Operator | null = null;
  private showingResult = false;

  pressDigit(input: string): void {
    const target = this.operator === null ? "left" : "right";
    const current = this[target];

    if (this.showingResult && target === "left") {
      this.left = input === "." ? "0." : input;
      this.showingResult = false;
      return;
    }

    if (input === "." && current.includes(".")) {
      return;
    }

    const next = current === "0" && input !== "." ? input : `${current}${input}`;
    this[target] = current === "" && input === "." ? "0." : next;
  }

  pressOperator(nextOperator: Operator): void {
    if (this.operator !== null && this.right !== "") {
      this.evaluate();
    }

    this.operator = nextOperator;
    this.showingResult = false;
  }

  pressClear(): void {
    this.left = "0";
    this.right = "";
    this.operator = null;
    this.showingResult = false;
  }

  evaluate(): number {
    const lhs = Number(this.left);
    const rhs = Number(this.right || this.left);

    const result = (() => {
      switch (this.operator) {
        case "+":
          return lhs + rhs;
        case "-":
          return lhs - rhs;
        case "*":
          return lhs * rhs;
        case "/":
          return rhs === 0 ? Number.NaN : lhs / rhs;
        default:
          return lhs;
      }
    })();

    this.left = Number.isFinite(result) ? String(result) : "Error";
    this.right = "";
    this.operator = null;
    this.showingResult = true;
    return result;
  }

  render(): string {
    const expression = [this.left, this.operator ?? "", this.right].filter(Boolean).join(" ");
    const display = expression || "0";
    const legend = Object.values(buttonStyles)
      .map(({ label, tone, hex }) => `${label}:${tone}:${hex}`)
      .join(" | ");

    return `Calculator(display="${display}", legend="${legend}")`;
  }
}

const app = new CalculatorApp();

app.pressDigit("1");
app.pressDigit("2");
app.pressOperator("+");
app.pressDigit("7");
app.pressDigit(".");
app.pressDigit("5");

console.log(app.render());
console.log(`result = ${app.evaluate()}`);

app.pressOperator("*");
app.pressDigit("3");
console.log(`result = ${app.evaluate()}`);
