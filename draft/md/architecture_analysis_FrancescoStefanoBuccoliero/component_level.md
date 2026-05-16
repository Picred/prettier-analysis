# 3.3 Component Level (Level 3)
The Component layer zooms directly into the Core API Engine Container (src/main/), decomposing its monolithic core into individual, cooperating logical components. While traditional web-oriented or enterprise architectures rely heavily on layered or Model-View-Controller paradigms, Prettier’s inner core operates as a stream-processing compilation engine. Architecturally, it is structured around a rigorous Pipe and Filter architectural pattern.

## 3.3.1 Component Architectural Diagram (PlantUML)
The following PlantUML script maps the internal filters of the Core API and the data pipes that bind them together, using the standardized C4 Component extensions:

```plantuml
@startuml "Prettier_Component"
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

LAYOUT_WITH_LEGEND()
title Component Diagram for Prettier Core API (Pipe & Filter)

' External Systems and Containers crossing boundaries
Container(cli, "CLI Container", "Node.js", "Passes text stream and option primitives inward.")
System_Ext(ide, "IDE / Code Editor", "Passes active editor buffer strings inward.")

Container_Boundary(core_boundary, "Core API Container") {
    Component(parser_orchestrator, "Parser Orchestrator", "src/main/parser.js", "Resolves the dynamic parser strategy and executes the text-to-AST conversion filter.")
    Component(ast_massager, "AST Massager", "src/main/massage-ast.js", "Normalizes the syntax tree, stripping redundant nodes, structural noise, and irrelevant syntax tokens.")
    Component(doc_builder, "Doc Builder (Traverser)", "src/main/ast-to-doc.js", "Implements the Functional Visitor pattern to traverse the normalized AST and build the Doc Intermediate Representation (IR).")
    Component(printer, "Printer Engine", "src/language-*/print/", "Evaluates the layout commands within the Doc IR against line-width constraints to generate the formatted text output.")
}

' Boundaries Connections
Rel(cli, parser_orchestrator, "Invokes formatting pipeline with", "Function Call")
Rel(ide, parser_orchestrator, "Invokes formatting pipeline with", "Function Call")

' Pipe & Filter Streams
Rel(parser_orchestrator, ast_massager, "Streams Raw Abstract Syntax Tree (AST) via", "Pipe / Return Object")
Rel(ast_massager, doc_builder, "Streams Normalized/Clean AST via", "Pipe / Return Object")
Rel(doc_builder, printer, "Streams Doc IR Command Arrays via", "Pipe / Return Object")

@enduml

```
## 3.3.2 The Pipe and Filter Architectural Metaphor
The internal computation of Prettier functions as a uni-directional processing pipeline where data enters as raw text and undergoes a series of deterministic transformations. Each step acts as a standalone Filter, and the output of one filter serves as the immutable input (Pipe) for the next.
1. **Filter 1: Parser Orchestrator (src/main/parser.js):** 
This component ingests the raw text string. It acts as the gateway to the injected compiler strategies, invoking the active parser (e.g., Babel, TypeScript) to output a raw Abstract Syntax Tree (AST).

2. **Filter 2: AST Massager (src/main/massage-ast.js):** 
The raw AST is highly volatile and contains code layout discrepancies introduced by the developer (e.g., extra parentheses, varying comment positions). The Massager filter cleans and normalizes this tree, stripping away stylistic noise to guarantee that syntactically identical code produces an identical AST blueprint.

3. **Filter 3: Doc Builder (src/main/ast-to-doc.js):**
 This component navigates the massaged AST using the Functional Visitor Pattern (analyzed in Phase 2). It transforms the AST nodes into a highly specialized Intermediate Representation (IR) proprietary to Prettier, known as a Doc. A Doc object does not contain language-specific structures; it is a collection of abstract formatting instructions (e.g., concat, group, indent, lineSuffix).

4. **Filter 4: Printer Engine (src/language-*/print/):**
The final filter reads the Doc IR. It executes an optimization layout algorithm, measuring the length of text fragments against the configured printWidth constraint (e.g., 80 characters). It dynamically breaks groups and outputs the final formatted text stream.

## 3.3.3 Empirical Identification of SOLID Principle Violations**

*Any violation of the SOLID principles?* **Yes**, static structural analysis reveals a critical architectural violation of the **Single Responsibility Principle (SRP)** and the **Interface Segregation Principle (ISP)** within the Printer Engine component layer.

To substantiate this violation scientifically, we reference the structural coupling metrics extracted via *Madge* in Phase 1 (`dipendenze.txt`). The analysis identified the following files as high efferent coupling (**Hubs**) within the system:

* `src/language-js/print/estree.js` $\rightarrow$ **~38 outgoing dependencies**
* `src/language-js/print/flow.js` $\rightarrow$ **~38 outgoing dependencies**
* `src/language-js/print/typescript.js` $\rightarrow$ **~34 outgoing dependencies**

##### **1. Violation of the Single Responsibility Principle (SRP)**
The SRP dictates that *a module should have one, and only one, reason to change*. However, `estree.js` acts as a monolithic dispatching hub for the entire JavaScript language specification.

* **The Structural Flaw:** Instead of encapsulating distinct formatting behaviors, `estree.js` statically imports and dispatches control to dozens of highly specific sub-printers (e.g., `print/function.js`, `print/class.js`, `print/statement.js`, `print/literal.js`, `print/object.js`).
* **Reason to Change Matrix:** Consequently, `estree.js` inherits a massive matrix of reasons to change. A bug fix in how an arrow function is printed, a specification update for JavaScript class properties, or a new layout rule for object literals will **all** force a modification of this single file. This concentrates high architectural risk in a single point of failure.

##### **2. Violation of the Interface Segregation Principle (ISP)**
The ISP states that *clients should not be forced to depend on interfaces they do not use*. The monolithic centralization of `estree.js` breaks this principle entirely.

* **The Structural Flaw:** Because `estree.js` acts as the single unified print interface for any JavaScript node type, the core traversal engine (`ast-to-doc.js`) is forced to depend on this giant, all-knowing module. The traversal engine cannot request a sub-interface dedicated exclusively to printing "Statements" or "Expressions"; it must consume the entire monolithic dependency graph of `estree.js` and all of its 38 sub-modules. This high efferent coupling drastically increases technical debt and hampers independent testability, representing a severe structural architectural smell.