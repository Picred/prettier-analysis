# Software Design Draft

## 1. Dependencies

### Method and Tools Used
The dependency analysis was performed to evaluate the code and knowledge dependencies among the software modules within the Prettier project, specifically focusing on the `src/` directory to isolate the core business logic.
To extract code dependencies based on explicit `import` statements, tools such as `madge`, `dependency-cruiser`, and custom PowerShell scripts combined with standard Unix text processing utilities (`grep`, `awk`) were utilized. Furthermore, `dependency-cruiser` output metrics were analyzed to calculate Afferent Coupling (Fan-in), Efferent Coupling (Fan-out), Instability, and detecting circular dependencies.
For knowledge dependencies (logical coupling), `git log` was employed to analyze the recent commit history (e.g., the last 1000 commits from tags like `3.8.2`) to identify files that are frequently modified together in the same commits.

### Code Dependencies
Based on the explicit imports in the source code, we investigated which files act as central hubs (high efferent coupling), which serve as core foundational blocks (high afferent coupling), and which act as independent atomic utilities (low efferent coupling).

**High Efferent Coupling (Fan-out) - Files with the most dependencies:**
1. `src/language-js/print/flow.js` (35 imports)
2. `src/language-js/print/typescript.js` (33 imports)
3. `src/language-js/print/estree.js` (29 imports)
4. `src/main/plugins/builtin-plugins/production-plugins.js` (27 imports)
5. `src/language-markdown/printer-markdown.js` (21 imports)
6. `src/index.js` (18 imports)

*Why?* These files function as architectural "Hubs" or "Orchestrators" and show a very high Instability index (close to 97%). Prettier operates by parsing source code into an Abstract Syntax Tree (AST) and then transforming it into a formatted document. The language-specific printers (`flow.js`, `typescript.js`, `estree.js`) are "builders" that need to handle every single type of language construct (arrays, classes, functions, loops). Consequently, they aggregate numerous specialized micro-modules for each construct, explaining their immense fan-out. Files like `index.js` and `production-plugins.js` serve as system entry points, aggregating all supported plugins and languages to expose a unified API to the user.

**High Afferent Coupling (Fan-in) - The most "popular" files:**
Certain files are heavily depended upon; if they break, the system collapses.
1. `src/document/index.js` (Over 70 incoming dependencies): Prettier relies on an intermediate formatting representation called "Doc". This file exports the primitives required to build this format. Every supported language printer must import it.
2. `src/language-js/utilities/node-types.js` (Over 35 incoming dependencies): Acts as a dictionary for the AST node types, constantly queried by the JavaScript printing modules.
3. Cross-cutting utilities (e.g., `utilities/is-non-empty-array.js` or `main/comments/print.js`): Universal operations centralized to prevent code duplication, imported across parsers and printers of all languages.

**Low Efferent Coupling - Files with the least dependencies:**
1. `src/cli/options/create-minimist-options.js`
2. `src/common/ast-path.js`
3. `src/common/errors.js`
4. `src/document/printer/indent.js`

*Why?* These files are atomic utilities or "Leaves" located at the base of the dependency pyramid, boasting an Efferent Coupling (Ce) of 0. They contain pure logic, constant definitions, or simple helper algorithms. By strictly following the Single Responsibility Principle and avoiding core imports, they provide extreme stability. If the system undergoes massive refactoring, these leaf nodes will likely remain unchanged.

**Structural Integrity and Circular Dependencies:**
A circular dependency check using `madge --circular` identified two cycles located within the core formatting engine:
1. `document/builders/index.js` → `document/builders/align.js` → `document/builders/indent.js` → `document/utilities/assert-doc.js` → `document/utilities/index.js`
2. `document/utilities/assert-doc.js` → `document/utilities/index.js`

While circular dependencies are usually an "architectural smell" violating the Acyclic Dependencies Principle (ADP), their presence here is driven by the highly recursive nature of the "Doc" data structure. Builders and utilities operate symbiotically on the same recursive definitions.

### Knowledge Dependencies
Knowledge dependencies were identified by evaluating logical coupling through co-change analysis in the Git history. 

**Inconsistencies with Code Dependencies:**
While many co-changes correctly mirrored code dependencies (e.g., core pipeline components changing together), several glaring inconsistencies were uncovered where files share zero static code links yet possess strong logical dependencies:

- **The JavaScript Parser Family:** Commits frequently modify `acorn.js`, `babel.js`, `espree.js`, `meriyah.js`, `oxc.js`, and `typescript.js` simultaneously. At a static level, these parsers are completely isolated alternative implementations for parsing JavaScript. They do not import one another. However, when Prettier adds support for a new JavaScript syntax or fixes a general parsing bug, every single supported parser must be updated to maintain system consistency.
- **Cross-Language Plugin Interfaces:** Commits simultaneously touch files like `get-visitor-keys.js` or `pragma.js` across entirely distinct language directories (e.g., `language-css`, `language-html`, `language-markdown`). A CSS formatter has absolutely no code dependency on an HTML formatter. However, because Prettier uses a standardized plugin architecture, whenever the API contract between the core engine and plugins evolves, developers are forced to concurrently update the interface files of all supported languages.
- **Package Management:** `package.json` and `yarn.lock` always co-change. This relationship reflects the Node.js ecosystem rules, completely detached from the application's internal code architecture.
- **Test Files and Source Files:** Changing a source behavior requires updating the corresponding test snapshots (e.g., a `.js` printer update breaks Markdown formatting snapshots). The dependency is mediated entirely by the test runner framework, not explicit imports.

---

## 2. Patterns

An extensive analysis of the source code revealed a sophisticated usage of architectural design patterns, necessary to manage the extreme complexity of a multi-language AST-based formatter. Below are 6 key patterns identified in the codebase.

### 2.1 Strategy Pattern (Behavioral)
**Classes/Role:** 
- **Context:** The Prettier Core orchestration module (`src/main/core.js` and `src/main/index.js`), which receives the file to format.
- **Strategy Interface:** The Plugin Contract. Prettier expects every strategy to expose standard capabilities like `parse` and `print`.
- **Concrete Strategies:** The individual plugin modules located in the `src/language-*` directories (e.g., `src/language-css/parser-postcss.js`, `src/language-html/index.js`).

**Why is it used? (Problem Solved):** The core formatting algorithm remains identical, but the specific parsing and printing rules vary drastically between languages. The Strategy pattern solves the problem of behavioral variation and tight coupling. The core engine does not need to know the intricacies of CSS or GraphQL; it simply delegates to the active strategy. This guarantees the Open/Closed Principle: new languages can be added entirely without modifying the core system, making it highly extensible and selecting the right tool at runtime based on file extensions.

**Alternatives (Pros & Cons):** 
- *Alternative:* A massive monolithic procedural `switch-case` statement residing in the core.
- *Pros:* Easier to trace execution flow linearly for very small, single-language projects. Might be marginally faster by avoiding dynamic loading.
- *Cons:* Disastrous for scalability. It completely blocks community extensibility (third-party plugins), and any update carries a high risk of breaking unrelated languages due to massive code entanglement.

### 2.2 Visitor Pattern (Behavioral)
**Classes/Role:** 
Because Prettier uses functional paradigms, formal classes are absent, but the roles are distinct:
- **Visitor:** The Printer module (e.g., `src/language-js/print/estree.js`), utilizing the central dispatcher function `genericPrint()` containing a large `switch (node.type)` block.
- **Element:** The Abstract Syntax Tree (AST) nodes (e.g., `IfStatement`, `BinaryExpression`). These are pure JSON objects generated by external parsers.
- **Navigator:** `createGetVisitorKeysFunction` serves as the map instructing the Visitor on which keys contain traversable child nodes.

**Why is it used? (Problem Solved):** An AST is a complex, deep hierarchical tree with dozens of distinct node types. Prettier uses the Visitor pattern to decouple the formatting algorithm from the physical AST data structure. Because code is a tree of trees, the pattern manages this recursive nature elegantly, applying node-specific formatting logic without altering the node definitions.

**Alternatives (Pros & Cons):** 
- *Alternative:* Injecting `print()` methods directly inside the AST node classes (procedural/classic OOP).
- *Pros:* Excellent encapsulation, highly intuitive (e.g., `node.print()`), and less boilerplate.
- *Cons:* Utterly impossible when AST nodes are generated by third-party libraries (like Babel or Flow). It violates the Single Responsibility Principle by polluting purely structural data representations with complex formatting behaviors.

### 2.3 Composite Pattern (Structural)
**Classes/Role:** 
- **Component:** The `Doc` interface/union type (`src/document/builders/index.js`), representing any formatting fragment.
- **Leaf:** Base atomic elements that do not contain other `Doc` objects (e.g., basic strings, `line`, `trim`).
- **Composite:** Complex layout structures like `group`, `indent`, `align`, or simple `Arrays`. These enclose child `Doc` fragments, forming infinitely nested hierarchies.

**Why is it used? (Problem Solved):** Prettier's defining feature is its Intermediate Representation (IR). Instead of printing text directly, it builds a `Doc` tree. The Composite pattern solves the fundamental problem of "Line Wrapping Management". Because Leaf nodes and Composite nodes share the same interface, the rendering engine (`src/document/printer/printer.js`) evaluates simple text and deeply nested groups uniformly. This preemptively calculated layout allows the engine to measure a `group`'s width and intelligently "break" it across multiple lines if it exceeds the maximum column limit (e.g., 80 characters).

**Alternatives (Pros & Cons):** 
- *Alternative:* Single-Pass String Builder (direct string generation while navigating the AST).
- *Pros:* Marginally faster execution and lower memory overhead since no intermediate tree is allocated.
- *Cons:* Advanced formatting becomes a maintenance nightmare. Code would be flooded with endless lookahead logic and conditional checks for line lengths, completely entangling formatting intent with spatial calculation.

### 2.4 Command Pattern (Behavioral)
**Classes/Role:** 
- **Command:** The `Doc` objects containing layout instructions (`indent`, `group`, `break`).
- **Invoker/Interpreter:** The `printDocToString(doc, options)` function in `src/document/printer/printer.js`.
- **Client:** The language-specific printers queueing these operational instructions.

**Why is it used? (Problem Solved):** The pattern separates the "intent" to format from the actual physical string rendering. The engine accumulates commands and evaluates them in a controlled environment. Crucially, this allows for "backtracking": the engine can simulate the execution of a `Doc` command queue, verify if the resulting text fits the line width, and discard or alter the layout strategy if it fails, which is the cornerstone of Prettier's intelligent formatting.

**Alternatives (Pros & Cons):** 
- *Alternative:* Immediate recursive string concatenation.
- *Pros:* Faster raw execution.
- *Cons:* Once a string is concatenated and printed, it cannot be "undone". Intelligent context-aware line-wrapping is impossible to achieve reliably.

### 2.5 Facade Pattern (Structural)
**Classes/Role:** 
- **Facade:** `src/index.js`
- **Subsystems behind the facade:** `src/main/core.js`, plugin loaders (`src/main/plugins/index.js`), configuration resolvers (`src/config/resolve-config.js`), etc.

**Why is it used? (Problem Solved):** Prettier is composed of numerous intricate submodules managing formatting, comment attachment, plugin discovery, and option resolution. The Facade pattern exposes a heavily simplified interface (`format()`, `check()`) to the outside world. It hides the brutal internal complexity, preventing users or integrators from having to manually wire parsers and options together.

**Alternatives (Pros & Cons):** 
- *Alternative:* Direct exposure of all internal submodules.
- *Pros:* Maximum granular control for power users.
- *Cons:* A highly unstable public API where internal refactoring immediately breaks third-party implementations and a steep learning curve for integration.

### 2.6 Builder Pattern (Creational)
**Classes/Role:** 
- **Builder:** The utility functions in `src/document/builders/` (e.g., `group()`, `indent()`, `ifBreak()`).
- **Product:** The final `Doc` intermediate representation structure.

**Why is it used? (Problem Solved):** To create the nested `Doc` trees dynamically, the system provides pure functions that abstract away the complex object instantiation. It ensures the printer logic remains focused on algorithms rather than the verbose boilerplate of JSON object creation, guaranteeing uniform creation of valid AST fragments.

**Alternatives (Pros & Cons):** 
- *Alternative:* Direct manual instantiation of JSON objects inside the printer files.
- *Pros:* Slightly fewer function calls.
- *Cons:* Extremely verbose, highly error-prone, and very fragile if the internal definition of a `Doc` node changes in the future.

---

## 3. Summary

**Summary of the findings of the two design aspects:**
The architectural design of Prettier demonstrates an exceptional degree of modularity, deliberately engineered to tackle the immense complexity of supporting dozens of different programming languages with perfectly consistent formatting rules. 

From the **Dependency Analysis**, the repository exhibits a healthy, pyramid-like structure. Complex orchestrators ("Hubs") manage the macroscopic execution flow by aggregating numerous dependencies, while at the bottom, "Leaf" utilities provide zero-dependency, hyper-stable support functions. The discovery of specific circular dependencies in the core highlights the recursive nature of formatting algorithms rather than poor design. The **Knowledge Dependencies** via co-change analysis provided vital insight: physical code coupling is only half the story. The plugin-based architecture forces developers to synchronize updates across statically independent files (such as multiple parallel parsers or cross-language plugin APIs), proving that architectural interfaces often dictate development workflows stronger than explicit imports.

From the **Pattern Analysis**, Prettier's structural and behavioral decisions perfectly align with its core mission. By utilizing the **Facade** pattern, it hides a massive ecosystem behind a trivial API. The **Strategy** pattern guarantees absolute extensibility, allowing community plugins to seamlessly integrate. The **Visitor** pattern ensures that the system's formatting logic remains untethered from external, third-party data structures (ASTs). Finally, the combination of **Composite**, **Command**, and **Builder** patterns orchestrates Prettier's true innovation: an Intermediate Representation (Doc) that mathematically guarantees optimal line wrapping and grouping by calculating spatial constraints before any text is actually rendered. Together, these design aspects ensure Prettier remains robust, testable, and infinitely scalable.