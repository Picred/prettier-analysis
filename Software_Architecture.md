# Software Architecture

## 1. Introduction and Tooling

The primary goal of this report is to document and describe the software architecture of Prettier, an opinionated code formatter. The architecture is modeled using the **C4 notation**, detailing the system across three levels of abstraction: Context, Container, and Component.

**Tooling Declaration:** The C4 diagrams were created using the **Structurizr DSL** (`c4-model` tooling) to formally define entities, containers, components, and their relationships. 

Throughout the diagrams, different notations are used to indicate the type of relationships between elements:
- **Solid Lines (Synchronous/Direct Flow):** Represent a strong, direct, and immediate relationship. These are used when a component explicitly invokes another and awaits a response to continue its execution (e.g., direct function calls in RAM, synchronous file system reads).
- **Dashed Lines (Asynchronous/Loose Coupling):** Represent a weaker, indirect, or secondary relationship. These indicate dynamically loaded modules (plugins), asynchronous communication, or the passive passing of configuration metadata without strict execution dependencies.

---

## 2. Context Level

The System Context diagram illustrates Prettier's macroscopic integration into a developer's workflow, highlighting its boundaries and interactions with external environments.

![Context View Diagram](../media/System_Context_View.jpeg)
> *Figure 1: Context View Diagram*

### Entities and Explanations

- **Developer (Person):** The primary user who writes source code and defines styling criteria. The developer interacts with Prettier either manually through terminal commands or seamlessly via IDE integrations.
- **Prettier (System):** The core software system acting as the formatting engine. It parses unformatted code and rewrites it according to a strict set of standardized styling rules.
- **IDE / Editor (External System):** The graphical user interface where developers write code. It acts as a wrapper, invoking Prettier on file save or upon user request.
- **File System (External System):** The physical storage for source code and configuration files. It is strictly categorized as an external system because Prettier does not own, manage, or create the file system; it merely requests OS-level permissions to read and write the user's local files.
- **CI/CD Pipeline (External System):** An automated external system that executes formatting tasks (e.g., via GitHub Actions) to enforce styling compliance before merging code into a repository.

**Relationships:**
The Developer interacts directly with the IDE (GUI interaction) and the CLI (Terminal I/O). External systems like the IDE and CI/CD pipelines trigger Prettier, passing raw code and eventually receiving or writing back the formatted output. Prettier relies entirely on the OS File System for its Input/Output operations.

---

## 3. Container Level

The Container diagram zooms into the Prettier system, revealing the high-level execution blocks and how responsibilities are distributed before reaching the core formatting logic.

![Container View Diagram](../media/Container_View.jpeg)
> *Figure 2: Container View Diagram*

### Containers and Explanations

- **API Layer (Node.js/JavaScript):** The programmatic interface that exports isolated functions (e.g., `format()`). It serves as the primary gateway for integrations (like IDE plugins) that need to format strings in memory without writing to the disk.
- **CLI Layer (Node.js):** The command-line interface. It parses arguments, manages batch file processing, and handles standard input/output. Crucially, the CLI layer acts as a wrapper that internally invokes the API Layer; developers can bypass the CLI entirely by using the API directly.
- **Configuration Layer (JavaScript/cosmiconfig):** Responsible for resolving, parsing, and applying configuration rules (e.g., `.prettierrc`, `.editorconfig`). This layer reads from the external file system asynchronously and injects the resolved options into the API/Core engine.
- **Plugin System (JavaScript):** A dynamic loading mechanism for language parsers and printers. It allows Prettier to support new languages without modifying the core engine.
- **Processing Engine (JavaScript):** The core container housing the central formatting logic. It is essentially a pure function that takes an unformatted string and configuration options, and returns a formatted string.

### Relationship with Clean Architecture

Prettier's container design demonstrates a strong alignment with the blueprint of **Clean Architecture**. The architecture heavily relies on the **Dependency Rule**, where source code dependencies point strictly inward toward higher-level policies.

The **Processing Engine** acts as the core Entity/Use Case layer. It contains pure business logic (AST transformations) and is completely agnostic of how data is delivered to it. It does not know about terminal arguments, network requests, or disk I/O.
The **CLI Layer** and **API Layer** act as Interface Adapters (or Delivery Mechanisms). They handle the dirty work of interacting with the outside world (parsing arguments, reading from the OS file system) and then pass clean, in-memory strings to the Processing Engine. By isolating I/O and external frameworks into outer layers, Prettier ensures its core logic remains pure, highly testable, and decoupled from the execution environment.

---

## 4. Component Level

The Component diagram breaks down the **Processing Engine** container into its constituent functional parts, tracking the lifecycle of code formatting. We intentionally discard the internal components of the CLI, API, and Configuration containers from this level of analysis; as established by our Clean Architecture mapping, these containers act merely as interface adapters. Their internal complexities do not represent the core architectural behavior of the system, which is centralized entirely within the pure logic of the Processing Engine.

*(Insert Component Diagram Here)*
![Component View Diagram](../media/Component_View.jpeg)
> *Figure 3: Component View Diagram*

### Components and Explanations

- **Parser Layer:** Receives the raw string of source code from the API Layer. It consults the Configuration Layer and the Plugin System to select the appropriate third-party or internal parser (e.g., Babel for JavaScript, PostCSS for CSS). It transforms the string into an Abstract Syntax Tree (AST).
- **AST Processing:** Receives the raw AST. This component is responsible for generic AST massaging, which includes normalizing nodes and securely attaching comments to the correct AST nodes before printing begins. The communication here is synchronous, passing the in-memory AST object.
- **Printing Layer:** Traverses the manipulated AST and translates the tree structure into Prettier's intermediate representation (the `Doc` builder format). It then runs the core formatting algorithm (measuring line lengths, handling line breaks) to output the final formatted string.

### SOLID Principles Evaluation at Level 3

When analyzing the Component level (Level 3), the architecture generally adheres to SOLID principles, but we can observe nuanced design trade-offs:

- **Open/Closed Principle (OCP):** Prettier strictly respects OCP through its Plugin System. The parser and printing layers are open for extension (by adding new language plugins) but closed for modification. The core engine does not need to be rewritten to support a new language like Rust or SQL; it simply dynamically loads a new concrete strategy.
- **Single Responsibility Principle (SRP) Violations:** A potential violation of SRP can be observed historically in the `AST Processing` and `Printing Layer` regarding comment handling. Comments are notoriously difficult to format because they do not structurally belong to the AST in most languages. If a single central component is responsible for attaching comments for *all* syntax variations across multiple languages, it gathers multiple reasons to change (one for every quirk of a specific language's comment syntax). While Prettier mitigates this by delegating to plugins, any central fallback logic for generic AST massaging often risks bloating and violating SRP.

---

## 5. Architectural Characteristics

Prettier's architecture natively supports several critical quality attributes, heavily supported by its design choices.

### Extensibility and Testability
The strict separation between the CLI/API adapters and the Processing Engine guarantees extreme **testability**. Because the Processing Engine is a pure string-in, string-out mechanism without I/O dependencies, millions of test cases can be run instantly in memory. **Extensibility** is ensured by the plugin-based dynamic loading, preventing the core from becoming a monolithic bottleneck.

### Coupling and Cohesion Metrics
To support this architectural reasoning, an analysis of the system's dependencies (imports and Git co-changes) reveals a healthy, pyramid-like structure:

1. **High Efferent/Afferent Coupling (Hubs and Gravity Centers):** Modules acting as API entry points or core orchestrators (e.g., src/main/core.js, src/index.js) exhibit high Efferent Coupling (Fan-out). They act as architectural hubs, absorbing complexity by explicitly importing and coordinating dozens of internal subsystems to provide a unified API to the outside world. Conversely, core foundational components, such as the Doc builder utilities, exhibit high Afferent Coupling (Fan-in). These act as true architectural gravity centers; they import very little, but the vast majority of the system depends on them. If these foundational modules break, the ripple effect causes the entire system to collapse.
2. **Low Efferent Coupling (The Leaves):** At the base of the dependency pyramid are atomic utilities with an Efferent Coupling (Fan-out) of exactly 0. These contain pure algorithms and string manipulation helpers. Their zero-dependency nature makes them hyper-stable, embodying high cohesion and ensuring that massive system refactors will likely leave them untouched.

Furthermore, analyzing **Knowledge Dependencies** via Git co-change analysis demonstrates that the Plugin System architecture forces developers to synchronize updates across statically independent files. This proves that the architectural interfaces (the plugin contracts) dictate development workflows and logical coupling far stronger than the explicit `import` statements, validating the loose coupling visually represented by dashed lines in the C4 models.
