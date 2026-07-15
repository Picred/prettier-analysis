# Software Design & Architecture Analysis: Prettier

This repository is a fork of a project about [Prettier](https://github.com/prettier/prettier), dedicated to a comprehensive empirical study conducted for the **Software Design and Architecture** course, using a **Reverse Engineering** approach.

Instead of just looking at Prettier as a black-box tool, we reconstruct and document its internal architectural patterns, evaluate its adherence to SOLID principles, map its structural dependencies, and trace how design patterns solve its complex, multi-language formatting challenges.

---

## Project Overview

* **The Problem:** Software teams historically waste countless hours debating trivial stylistic choices. Traditional linters warn, but struggle with complex line-wrapping.
* **The Solution:** Prettier acts as a **stateless, opinionated string-to-string transformation engine**. It parses code into an Abstract Syntax Tree (AST), completely discards original formatting, and prints it from scratch adhering to strict column-width rules.
* **Scale of Analysis:** Focused on the core `src/` directory (~100,000 lines of JavaScript code), analyzing a system downloaded tens of millions of times weekly.

---

## 1. Software Architecture (C4 Model & Clean Architecture)

We modeled Prettier across three levels of abstraction using the **C4 Notation** and the **Structurizr DSL**:

### Context Level (Level 1)
Illustrates how Prettier integrates into a developer's workflow, mapping boundary interactions with the IDE, File System, and CI/CD pipelines.
> 🖼️ *Refer to `./media/Context_View.png` in the repository.*

### Container Level (Level 2)
Splits the system into high-level execution blocks: **API**, **CLI**, **Plugins**, **Processing Engine**, and **Document Engine**.
* **Clean Architecture Alignment:** Prettier strictly adheres to the **Dependency Rule**. The *Processing Engine* acts as the core Entity/Use Case layer (pure business logic, agnostic of I/O). The *CLI* and *API Layers* act as Interface Adapters handling external system communication (Node.js runtime, terminal arguments, disk I/O).

### Component Level (Level 3)
Breaks down the *Processing Engine* into: **Configuration Layer**, **Parser Layer**, **AST Processing**, and **Printing Layer**.
* **SOLID Evaluation:** * **OCP (Open/Closed):** Fully respected. Adding support for new languages requires adding new concrete plugins without modifying the core engine.
  * **SRP (Single Responsibility) Violations:** Identified minor historical trade-offs in AST Processing and Printing (e.g., comment attachment and node dispatching within `estree.js`).

---

## 2. Software Design & Coupling Analysis

To substantiate our architectural reasoning, we performed deep empirical analyses of code and knowledge dependencies.

### Code Dependencies (Static Analysis)
Using `dependency-cruiser` and `madge`, we identified key topological roles in the dependency graph:
* **High Efferent Coupling (Hubs/Orchestrators):** Core printers like `flow.js` (35 imports) and `typescript.js` (33 imports) act as hubs because they must import specialized micro-modules for every language construct.
* **High Afferent Coupling (Gravity Centers):** Foundational blocks like `src/document/index.js` (>90 incoming dependencies) hold the entire system's stability. A breaking change here triggers a massive ripple effect.
* **Low Efferent Coupling (Leaf Nodes):** Atomic utilities (e.g., `errors.js`, `indent.js`) have a Fan-out of exactly 0, embodying pure, stable logic.

### Knowledge Dependencies (Co-Change Analysis)
By mining the last 500 Git commits, we uncovered implicit coordination requirements:
* **Static vs. Logical Discrepancies:** Only 3 out of the top 10 most frequent co-changing file pairs share a direct static `import` dependency (e.g., `flow.js` + `type-annotation.js`).
* **Hidden Coupling:** Parallel parser implementations (`acorn.js`, `babel.js`, `espree.js`) frequently change together without importing each other, proving that the abstract architectural interfaces dictate development workflows far stronger than static code references.

---

## 3. Architectural Design Patterns

Prettier manages the extreme complexity of multi-language AST formatting through five key design patterns:

| Pattern | Role in Prettier | Key Problem Solved |
| :--- | :--- | :--- |
| **Strategy** *(Behavioral)* | Core Engine acts as the Context; language-specific plugins in `src/language-*` act as Concrete Strategies. | Dynamically resolving language parsing rules without coupling the core engine to specific syntaxes. |
| **Visitor** *(Behavioral)* | Printer modules (e.g., `estree.js`) act as Visitors; AST nodes act as visited Elements. | Navigating deeply recursive syntax trees and formatting them without mutating third-party AST structures. |
| **Composite** *(Structural)* | The `Doc` interface acts as the Component, implemented by Leaf nodes (strings) and Composites (`group`, `indent`). | Treating simple text and complex nested formatting blocks uniformly to calculate dynamic line wrapping. |
| **Facade** *(Structural)* | `src/index.js` provides a simplified API (`format()`, `check()`) shielding users from underlying subsystems. | Hiding a massive subsystem (parsers, configuration, comment handlers) behind a trivial programmatic gateway. |
| **Builder** *(Creational)* | Functional builders (`group()`, `indent()`, `ifBreak()`) in `src/document/builders/` generate the final complex `Doc`. | Eliminating object construction boilerplate and preventing error-prone manual JSON object instantiation in printers. |

---

## 📂 Repository Structure

```bash
├── media/                   # C4 Diagrams & Pattern Visualizations
├── src/                     # Prettier Core Source Code (Analyzed)
├── Software_Architecture.md # Detailed Software Architecture Report (C4, SOLID)
├── Software_Design.md       # Detailed Software Design Report (Metrics, Co-changes, Patterns)
└── README.md                # Project Entry Point (This file)
