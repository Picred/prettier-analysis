# 3.1 Context Level (Level 1)
The System Context layer establishes the absolute boundaries of Prettier, treating the entire system as a single, deterministic, and stateless execution unit ("black box"). Rather than analyzing internal logic, this level delineates how Prettier navigates external forces, identifies the exact actors invoking the system, and maps the peripheral tooling required to operate within a modern development lifecycle.

## 3.1.1 Empirical Identification of External Actors and Systems
Instead of relying on abstract assumptions, the identification of external systems and communication channels is derived directly from structural metadata within the project repository:

Automated Environment Gateway (package.json -> "bin")
The configuration file package.json explicitly defines a binary distribution command:

JSON
"bin": "./bin/prettier.cjs"
This metadata instructs the host operating system to register Prettier as a command-line executable. Architecturally, this provides empirical evidence for the existence of the CI/CD Pipeline & Git Hooks external system. Automated validation tools (e.g., Husky for pre-commit verification or GitHub Actions for continuous integration) invoke this binary to perform style gatekeeping. The interaction is strictly governed by command-line arguments and standard operating system exit codes (0 for successful compliance, 1 for formatting discrepancies).

Programmatic Integration Gateway (package.json -> "main" & "exports")
The core configuration dictates how third-party software imports Prettier as a module dependency:

JSON
"main": "./src/index.cjs",
"exports": {
  ".": {
    "types": "./src/index.d.ts",
    "require": "./src/index.cjs",
    "default": "./src/index.js"
  },
  "./standalone": "./src/standalone.js"
}
This entry-point matrix proves that Prettier targets an external **IDE / Code Editor** environment (such as *Visual Studio Code* or *WebStorm*). Editors do not wrap shell executions; instead, they load the programmatic API directly into memory (`import prettier from "prettier"` via `src/index.js`). When a "Format on Save" event triggers, the IDE passes the raw text buffer directly across this programmatic boundary and expects a synchronous or asynchronous string response.

3.  **Environment-Agnostic Core (`package.json -> "browser" & standalone.js`)**
  The explicit declaration:
  ```json
  "browser": "./standalone.js"
  ```
  paired with `standalone.js` acting as a specialized export layer, provides critical architectural evidence. It demonstrates that Prettier's formatting engine is entirely decoupled from Node.js runtime environments (such as file systems or network sockets). By exposing a standalone variant, Prettier certifies its capability to run natively within client-side web browsers, confirming that the core domain logic is purely mathematical and transformational.

## **3.1.2 Architectural Rationale and System Boundaries**
Mapping these boundaries within the C4 Context diagram is vital for several structural reasons:

* **Enforcement of a Stateless, Deterministic Invariant:** Prettier acts as a pure function: $f(\text{RawText, Options}) \rightarrow \text{FormattedText}$. By segregating the IDE and CI/CD as external systems, the C4 model highlights that Prettier does not maintain a database, does not manage persistent states, and does not autonomously monitor file changes. All state management and I/O triggering are delegated to peripheral actors.
* **Decoupling Input/Output Operations:** Prettier never assumes responsibility for rendering layout colors or drawing graphical interfaces. It takes a raw string, computes the optimized abstract layout, and returns a clean string. The responsibility of displaying this text to the human actor (**The Software Developer**) is delegated entirely to the external IDE layer, maximizing the separation of concerns.

## **3.1.3 System Context Diagram (PlantUML)**

The following PlantUML script formally models these high-level relationships, utilizing the standardized C4 layout definitions to represent the system boundaries and communication protocols:

```plantuml
@startuml "Prettier_Context"
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

LAYOUT_WITH_LEGEND()
title System Context Diagram for Prettier

' Actors
Person(developer, "Software Developer", "Writes and maintains source code in various programming languages.")

' Systems
System(prettier, "Prettier", "Opinionated Code Formatter. Parses code and re-prints it with its own rules, enforcing a consistent style.")

' External Systems
System_Ext(ide, "IDE / Code Editor", "VS Code, WebStorm, Vim, etc. Provides the interface for the developer.")
System_Ext(ci_cd, "CI/CD & Git Hooks", "Automated pipelines or pre-commit hooks (e.g., Husky, GitHub Actions).")

' Relationships
Rel(developer, ide, "Writes unformatted code in")
Rel(developer, ci_cd, "Commits code to")

Rel(ide, prettier, "Sends raw code & config to", "API/CLI")
Rel(prettier, ide, "Returns formatted code to", "API/CLI")

Rel(ci_cd, prettier, "Triggers formatting checks", "CLI")
Rel(prettier, ci_cd, "Returns success/fail status", "Exit Codes")
@enduml