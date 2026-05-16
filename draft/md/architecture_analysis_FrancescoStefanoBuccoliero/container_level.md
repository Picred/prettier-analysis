# 3.2 Container Level (Level 2)
The Container layer shifts the architectural focus from ecosystem boundaries to the high-level executable and logical boundaries within Prettier itself. In the context of a JavaScript/Node.js library, "containers" do not represent separate OS-level containerization (like Docker) or network-isolated microservices; instead, they represent distinct, decoupled architectural subsystems operating in separate logical scopes with strict interface boundaries.

## 3.2.1 Container Architectural Diagram (PlantUML)
The following PlantUML script formally maps Prettier’s structural containers and their cross-boundary communication protocols using the standardized C4 Container library:

```plantuml
@startuml "Prettier_Container"
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

LAYOUT_WITH_LEGEND()
title Container Diagram for Prettier System

' External Actors and Systems
Person(developer, "Software Developer", "Uses Prettier to format source code files.")
System_Ext(ide, "IDE / Code Editor", "Triggers formatting programmatic calls on save.")
System_Ext(ci_cd, "CI/CD & Git Hooks", "Triggers batch formatting checks via CLI bin.")

' Prettier System Boundary
System_Boundary(prettier_system, "Prettier System") {
    Container(cli, "CLI Container", "Node.js (src/cli/)", "Handles Operating System interactions: parses CLI flags, reads/writes files on disk, and extracts local configuration files.")
    Container(core, "Core API Engine", "JavaScript (src/main/)", "The decoupled execution domain. Orchestrates the AST pipeline, applies formatting rules, and manages printing constraints. Environment-agnostic.")
    Container(plugins, "Plugins Extension System", "JavaScript (src/plugins/)", "Language-specific parser and printer extensions (e.g., HTML, CSS, Markdown) injected into the core.")
}

' External Relationships
Rel(developer, ci_cd, "Commits code to")
Rel(developer, ide, "Writes code in")

' Boundary Crossings
Rel(ci_cd, cli, "Invokes batch processing via", "Shell/Bin Execution")
Rel(ide, core, "Invokes formatting programmatic API via", "Node Module Import")

' Internal Subsystem Relationships
Rel(cli, core, "Instantiates and passes raw strings to", "Programmatic Function Call")
Rel(core, plugins, "Dynamically queries and invokes interfaces from", "Inversion of Control (IoC)")
@enduml
```

## 3.2.2 Relationship with the Clean Architecture Blueprint
Did we find any relationship with the Clean Architecture blueprint? Yes, Prettier implements a strict textbook adaptation of Robert C. Martin’s Clean Architecture principles.

The segregation of Prettier's subsystems perfectly mirrors the concentric rings of Clean Architecture, prioritizing the Dependency Rule: dependencies can only point inward, toward higher-level policies (the core domain).

1. Core API Engine as the Inner Ring (Entities & Use Cases)
The src/main/ directory contains the pure, untainted domain logic of the application (the formatting engine).

Runtime Agnosticism: As verified by the package.json metadata which exports ./standalone.js for browser environments, the Core API container has zero dependencies on Node.js-specific core modules (such as fs or path). It is a pure data-transformation engine.

Static Verification of the Dependency Rule: Cross-referencing this structure with our static analysis data (dipendenze.txt) reveals that src/main/core.js never imports any asset from src/cli/. The core domain logic remains completely blind to how it is invoked, protecting the core business rules from external environment changes.

2. CLI Container as the Outer Ring (Interface Adapters / Controllers)
The src/cli/ directory represents the infrastructure and adapter layer. Its sole responsibility is to translate low-level, environment-specific inputs into standard data formats suitable for the inner core ring.

Boundary Translation: The CLI reads raw binary files from disk, handles I/O exceptions, and parses command-line arguments using Node.js capabilities. It then packages these raw details into two simple javascript data primitives: a text string and an options object.

Inward Flow of Control: The CLI then crosses the architectural boundary by importing src/index.cjs (as configured in package.json -> "main") and invoking the inner layer. This represents a clean separation of concerns: if the operating system's file management system changes, only the CLI ring is modified; the Core formatting logic remains untouched.

3. Plugins and the Dependency Inversion Principle (DIP)
The most compelling evidence of Clean Architecture within Prettier is its handling of language-specific parsers (Babel, TypeScript, Flow).

The Monolithic Trap Avoided: If the Core API statically imported every compiler parser, the inner core would become tightly coupled to volatile external third-party libraries, destroying architectural stability.

Inversion of Control (IoC): Prettier resolves this via the Dependency Inversion Principle. The Core API defines an abstract contractual interface: it expects any incoming "Parser strategy" to expose a function signature named .parse(text, options).

Dynamic Injection: As confirmed by our source code inspection of standalone.js and src/main/parser.js, the core does not know which parser it is executing. The outer layer extracts the plugins array from user arguments (options.plugins ?? []) and dynamically injects them into the Core pipeline at runtime:

JavaScript
const parser = await resolveParser(options);
ast = await parser.parse(text, options);
Consequently, the plugins act as interchangeable plug-ins (Frameworks/Drivers layer) hanging off the inner abstract boundaries of the Core, fulfilling the ultimate goal of Clean Architecture.