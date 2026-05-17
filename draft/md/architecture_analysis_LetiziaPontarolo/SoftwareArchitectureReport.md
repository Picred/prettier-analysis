# Software Architecture Report — Prettier
## Introduction
This report analyzes the software architecture of Prettier using the C4 model. The objective is to describe the system architecture at different abstraction levels, identify the major architectural decisions adopted by the project, and evaluate the system according to software engineering principles such as modularity, extensibility, maintainability, and SOLID compliance.

The architectural analysis is divided into three levels:
1. System Context Diagram 
2. Container Diagram 
3. Component Diagram  

The diagrams were implemented using:
- PlantUML 
- C4-PlantUML  

The report also discusses the relationship between Prettier’s architecture and the Clean Architecture blueprint, possible violations of SOLID principles, and important architectural characteristics supported by the system design.

## Context Level
The System Context Diagram provides a high-level representation of the ecosystem in which Prettier operates. At this level, the system is represented as a black box, while the focus is placed on external actors and systems interacting with it.

The primary actor is the Software Developer. Developers use Prettier during software development activities in order to automatically format source code according to consistent stylistic rules. Prettier reduces discussions about code style and allows development teams to focus more on functionality and maintainability.

Another important external system is the Code Editor / IDE. Editors such as Visual Studio Code or WebStorm integrate Prettier through extensions or plugins. These integrations commonly provide “format on save” capabilities, where source code is automatically formatted whenever a file is saved. In this scenario, the editor acts as an orchestrator that invokes Prettier programmatically.

The CI/CD Pipeline represents automated systems used during software delivery workflows. Examples include GitHub Actions, GitLab CI, or Jenkins. These systems execute Prettier automatically to verify formatting consistency across repositories or to enforce formatting rules before deployment.

The context-level architecture reveals that Prettier behaves as an infrastructural development utility integrated into multiple stages of the software development lifecycle. Unlike end-user applications, Prettier is designed to be embedded into external workflows and tools.

Another relevant architectural observation is that Prettier supports multiple usage modes simultaneously:
- interactive usage through IDEs 
- direct usage through terminal commands 
- automated execution in CI/CD environments 
- programmatic usage through APIs 

This flexibility is one of the reasons for the widespread adoption of the system.

At this abstraction level, internal implementation details such as parsers, AST transformations, printers, and plugins are intentionally omitted. The goal of the Context Diagram is not to explain how Prettier works internally, but rather to identify its role within the broader software ecosystem.

The Context Diagram also highlights an important non-functional characteristic: integration capability. Prettier is designed to integrate seamlessly with external development environments, which strongly influences its architectural structure.

## Container Level
The Container Diagram provides a more detailed view of Prettier’s internal architecture by decomposing the system into major containers.

The first container is the CLI (Command Line Interface). This container exposes Prettier functionality through terminal commands such as:

```
prettier --write .
prettier --check .
```
The CLI is mainly used by developers and CI/CD pipelines. It handles argument parsing, configuration loading, target file selection, and orchestration of formatting operations. From an architectural perspective, the CLI acts as an access layer between external actors and the core formatting services.

The Public API container exposes Prettier as a reusable JavaScript library. This container is essential for editor integrations and third-party tools. Instead of invoking terminal commands, editors typically access Prettier directly through its API. This design improves efficiency and simplifies integration with development tools.

The existence of both CLI and Public API containers demonstrates an important architectural quality: separation of interfaces from business logic. Different clients can interact with the same formatting capabilities through different interfaces without duplicating formatting functionality.

The Configuration Resolver container centralizes configuration management. It loads formatting options from files such as:

```
.prettierrc
prettier.config.js
package.json
```

This container improves maintainability because configuration logic is isolated from formatting logic. Centralizing configuration resolution also ensures consistent behavior across all usage modes.

The Formatting Engine represents the core computational container of the system. It performs source code parsing, AST processing, layout generation, and final output rendering. This container contains the most important architectural logic of the system and therefore becomes the focus of the Component Diagram.

The Plugin / Language Support container provides support for multiple programming and markup languages. This architectural decision is fundamental for scalability and extensibility. Instead of hardcoding language-specific behavior inside the formatting engine, Prettier delegates parser and printer implementations to plugins.

This plugin-oriented design significantly reduces coupling between generic formatting orchestration and language-specific implementations. It also enables independent evolution of language support modules.

The Container Diagram reveals several architectural patterns and design decisions.

First, the architecture is strongly layered. External actors interact only with interface containers such as the CLI or Public API. Internal formatting details remain encapsulated inside lower-level containers.

Second, the system demonstrates high modularity. Each container has a relatively clear responsibility:
- CLI → user interaction 
- API → programmatic integration 
- Configuration Resolver → configuration management 
- Formatting Engine → formatting orchestration 
- Plugin Support → language-specific behavior 

This separation improves understandability and facilitates independent development and maintenance.

Third, the architecture follows a service-oriented internal organization. The Formatting Engine behaves as a reusable service accessed through multiple delivery mechanisms.

Another important observation concerns dependency direction. High-level orchestration flows from external interfaces toward the formatting engine and finally toward language-specific implementations. This structure reduces the risk of circular dependencies and supports extensibility.

The Container Diagram also highlights an important architectural tradeoff. Prettier prioritizes flexibility and extensibility over minimalism. Supporting many interfaces, languages, and integration scenarios increases architectural complexity, but this complexity is justified by the broad ecosystem integration goals of the project.

## Relationship with Clean Architecture
Prettier exhibits several similarities with the principles of Clean Architecture, although it does not implement the blueprint strictly or explicitly.

One of the most evident similarities is the separation between external delivery mechanisms and core business logic. In Prettier, the CLI and Public API containers behave similarly to interface adapters. Their purpose is to expose functionality to external actors while delegating actual formatting operations to the formatting engine.

The Formatting Engine itself resembles the application core of Clean Architecture. It contains the main formatting workflow and orchestrates interactions between parsers, printers, and intermediate formatting structures.

The architecture also demonstrates partial dependency inversion. High-level formatting orchestration depends on parser/printer abstractions rather than concrete language implementations. Language support modules extend the system through plugins without requiring modifications to the core engine.

This plugin-based structure is highly aligned with the Open/Closed Principle and with the idea of protecting the application core from external implementation details.

Another similarity with Clean Architecture is the attempt to isolate infrastructure concerns. Configuration management, editor integrations, and command-line interactions are separated from the formatting logic itself.

However, Prettier does not fully follow Clean Architecture in a strict enterprise-oriented sense.

First, the system lacks explicit domain entities and use-case layers. Prettier is primarily a transformation pipeline rather than a business-domain application. Therefore, many classical Clean Architecture concepts are less relevant.

Second, several internal modules are tightly coupled to the JavaScript ecosystem and runtime environment. The architecture prioritizes pragmatic implementation choices over strict architectural isolation.

Third, the system organization is more pipeline-oriented than domain-oriented. Components are organized around formatting stages rather than business capabilities.

Despite these limitations, Prettier still demonstrates many principles associated with Clean Architecture:
- separation of concerns 
- dependency control 
- extensibility through abstractions 
- encapsulation of infrastructure details 
- reusable application core 

The architecture can therefore be considered partially aligned with Clean Architecture principles while remaining intentionally lightweight and pragmatic.

## Component Level
The Component Diagram focuses on the internal structure of the Formatting Engine container.

The Parser Selector component determines which parser should be used depending on language, file extension, or configuration options. This component improves extensibility because the engine itself does not need hardcoded knowledge about every supported language.

The Parser component converts source code into an Abstract Syntax Tree (AST). The AST is a structured representation of the program independent from formatting details. Using an AST-based architecture allows Prettier to reason about code semantics rather than raw text.

This design decision is fundamental because it enables reliable formatting transformations without modifying the logical behavior of the source code.

The Comment Attacher component manages comments and associates them with appropriate AST nodes. Comments are often problematic during formatting because they are not always represented naturally inside syntax trees. Dedicated comment management therefore becomes necessary.

The AST Preprocessor prepares and normalizes AST structures before formatting. Different parsers may produce slightly different AST representations, and preprocessing helps standardize these structures for later stages.

The Printer component is one of the most important architectural elements of Prettier. Instead of directly generating formatted text, it converts the AST into an intermediate representation called “Doc”.

This intermediate representation is a particularly interesting architectural decision because it separates logical formatting decisions from final rendering decisions.

The Doc Builders component creates composable formatting structures such as:

```
group
line
softline
indent
join
```

These structures describe formatting intentions abstractly without immediately deciding where line breaks will occur.

Finally, the Doc Printer component converts the intermediate representation into final formatted source code. During this stage, Prettier evaluates line width constraints and determines optimal layout strategies.

The entire formatting process therefore behaves as a transformation pipeline:

```
Source Code
→ AST
→ Intermediate Representation
→ Formatted Output
```

This pipeline architecture improves modularity because each component focuses on a specific transformation stage.

The Component Diagram also highlights the importance of plugin integration. Both parsers and printers are partially provided through the Plugin / Language Support container. This reduces direct coupling between the formatting engine and individual programming languages.

Another important architectural characteristic visible at the component level is determinism. Each transformation stage contributes to producing stable and predictable formatting output. Deterministic behavior is essential because inconsistent formatting would reduce developer trust in the system.

The architecture also emphasizes composability. The Doc representation allows formatting rules to be composed hierarchically, improving flexibility and readability of formatting logic.

Additionally, the component-level organization reveals a strong separation between syntax analysis and rendering. Parsing concerns remain distinct from layout generation concerns, which improves maintainability and facilitates independent evolution of components.

## SOLID Principles Analysis
At the component level, Prettier generally demonstrates good adherence to SOLID principles, although some limitations can be observed.

### Single Responsibility Principle (SRP)
Most components respect SRP reasonably well.

Examples include:
- Parser Selector → parser selection 
- Comment Attacher → comment handling 
- Doc Printer → rendering final output 

Each component performs a relatively focused task within the formatting pipeline.

However, some printer implementations partially violate SRP because they combine formatting decisions, layout logic, and language-specific formatting rules. As support for additional syntax features grows, printer implementations may become extremely large and difficult to maintain.

### Open/Closed Principle (OCP)
Prettier strongly follows OCP through its plugin architecture.

The core formatting engine can support new languages without major internal modifications. External plugins extend system behavior while preserving stability of the existing architecture.

This extensibility model represents one of the strongest architectural aspects of the project.

### Liskov Substitution Principle (LSP)
The architecture generally respects LSP because parsers and printers conform to expected interfaces and can be substituted transparently.

However, some language-specific exceptions occasionally require custom handling, slightly weakening substitutability.

### Interface Segregation Principle (ISP)
Prettier partially follows ISP.

The separation between CLI, Public API, and formatting internals prevents clients from depending on unnecessary functionality.

Nevertheless, some internal APIs remain broad and tightly coupled to Prettier-specific abstractions.

### Dependency Inversion Principle (DIP)
The system partially follows DIP.

High-level formatting orchestration depends on abstract parser/printer contracts rather than concrete implementations.

However, several internal modules still depend heavily on concrete JavaScript runtime structures and ecosystem-specific utilities.

Overall, Prettier demonstrates pragmatic rather than dogmatic adherence to SOLID principles. The project balances architectural cleanliness with performance, usability, and ecosystem integration requirements.

## Architectural Characteristics
Several important architectural qualities emerge from the analysis.

### Extensibility
Extensibility is one of the strongest characteristics of Prettier.

The plugin-based architecture allows new languages and formatting capabilities to be added without significant modifications to the core engine. This supports ecosystem growth and long-term maintainability.

### Modularity
The architecture demonstrates strong modular decomposition.

Responsibilities are distributed across multiple containers and components with relatively clear boundaries. This improves understandability and simplifies maintenance activities.

### Reusability
The Public API enables reuse across editors, IDEs, automation tools, and external integrations.

The formatting engine itself behaves as a reusable service independent from delivery mechanisms.

### Maintainability
The separation between parsing, formatting, rendering, and configuration management improves maintainability.

However, some language-specific printer implementations remain highly complex and may increase maintenance costs over time.

### Scalability
Although Prettier is not a distributed system, scalability remains relevant in terms of language support and ecosystem integration.

The plugin-oriented architecture scales effectively because new capabilities can be added incrementally without redesigning the core system.

### Determinism and Consistency
One of the most important architectural qualities of Prettier is deterministic behavior.

Given the same input and configuration, the system always produces identical output. This consistency reduces stylistic conflicts and improves collaboration inside software teams.

### Integration Capability
Prettier is highly integrable.

The coexistence of CLI and API interfaces allows the system to operate in many different environments, including editors, build pipelines, and automation platforms.

### Coupling and Cohesion
The architecture generally demonstrates good cohesion because each component focuses on a specific responsibility.

Coupling is also relatively controlled due to the plugin-oriented design and layered architecture. However, some internal formatting modules remain tightly connected because formatting logic inherently requires coordination between parsing, layout generation, and rendering stages.

## Conclusion
The architecture of Prettier demonstrates a modular and extensible design centered around a reusable formatting engine.

The system combines:
- interface-based access through CLI and APIs 
- plugin-oriented extensibility 
- AST-driven transformation pipelines 
- intermediate formatting representations 
- deterministic rendering mechanisms 

The architecture shares several principles with Clean Architecture, particularly regarding separation of concerns and dependency control, while remaining pragmatic and lightweight.

At the component level, Prettier generally demonstrates good adherence to SOLID principles, especially concerning extensibility and modularity. The plugin architecture represents one of the most successful design decisions because it enables scalable language support without destabilizing the core engine.

Overall, Prettier is an example of a modern software architecture optimized for maintainability, extensibility, integration capability, and deterministic behavior within the software development ecosystem.
